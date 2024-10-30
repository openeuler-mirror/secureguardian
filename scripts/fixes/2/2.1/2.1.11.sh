#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Fix Script for 2.1.2
#
# #######################################################################################

#!/bin/bash

# 功能说明:
# 本脚本用于检测并修复 /etc/group 文件中重复的用户组名，确保每个组名唯一。
# 支持 --self-test 参数，用于验证逻辑，不使用硬编码。

# 初始化例外组名数组
exceptions=()

# 参数解析函数，支持 -e 和 --self-test 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a custom_exceptions <<< "$2"
        exceptions+=("${custom_exceptions[@]}")
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e 组名1,组名2,...] [--self-test]"
        exit 1
        ;;
    esac
  done
}

# 自测功能：手动向 /etc/group 添加重复的组名
self_test() {
  echo "自测模式: 创建测试组 testgroup，并手动添加重复的组名。"

  # 删除已有的测试组
  for group in testgroup; do
    if getent group "$group" &>/dev/null; then
      echo "删除已存在的测试组 $group..."
      groupdel "$group"
    fi
  done

  # 创建第一个测试组
  groupadd testgroup
  echo "已创建测试组 testgroup。"

  # 手动向 /etc/group 添加重复的组名
  echo "testgroup:x:$(get_next_available_gid):" >> /etc/group
  echo "已手动向 /etc/group 添加重复的组名 testgroup。"

  # 执行修复
  fix_duplicate_groupnames

  # 验证修复结果
  if ! awk -F':' '{print $1}' /etc/group | sort | uniq -d | grep -q 'testgroup'; then
    echo "自测成功: 重复的组名已成功修复。"
    groupdel testgroup
    return 0
  else
    echo "自测失败: 组名修复不正确。"
    return 1
  fi
}

# 获取系统中未占用的最小可用 GID
get_next_available_gid() {
  local gid=1000
  while getent group "$gid" &>/dev/null; do
    gid=$((gid + 1))
  done
  echo "$gid"
}

# 修复重复组名的函数
fix_duplicate_groupnames() {
  local duplicate_groupnames=$(awk -F':' '{print $1}' /etc/group | sort | uniq -d)

  if [ -n "$duplicate_groupnames" ]; then
    echo "发现重复的组名: $duplicate_groupnames，开始修复..."
    for groupname in $duplicate_groupnames; do
      local groups=($(awk -F':' -v name="$groupname" '$1 == name {print $1}' /etc/group))

      # 保留第一个组名，删除其余重复的组名
      for i in "${!groups[@]}"; do
        if [[ "$i" -eq 0 ]]; then
          echo "保留组名 ${groups[$i]}。"
        else
          echo "修复: 删除重复的组 ${groups[$i]}..."
          sed -i "/^${groups[$i]}:/d" /etc/group
          if [[ $? -eq 0 ]]; then
            echo "修复成功: 已删除重复的组 ${groups[$i]}。"
          else
            echo "修复失败: 无法删除组 ${groups[$i]}。"
            return 1
          fi
        fi
      done
    done
  else
    echo "所有组名均唯一，无需修复。"
  fi
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_duplicate_groupnames; then
  echo "修复完成: 所有组名已正确设置为唯一。"
  exit 0
else
  echo "修复失败: 部分组名未能正确修复。"
  exit 1
fi


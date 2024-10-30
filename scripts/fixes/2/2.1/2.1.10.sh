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
# Description: Security Baseline Fix Script for 2.1.10
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于检测并修复 /etc/group 文件中重复的 GID，确保每个 GID 唯一。
# 支持 --self-test 参数用于验证逻辑，不使用硬编码，动态查找未占用的 GID。

# 初始化例外 GID 数组
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
        echo "使用方法: $0 [-e GID1,GID2,...] [--self-test]"
        exit 1
        ;;
    esac
  done
}

# 获取系统中未占用的最小可用 GID
get_next_available_gid() {
  local gid=1000  # 从 1000 开始查找可用 GID
  while getent group "$gid" &>/dev/null; do
    gid=$((gid + 1))
  done
  echo "$gid"
}

# 自测功能：手动向 /etc/group 添加重复 GID，以验证修复逻辑
self_test() {
  echo "自测模式: 创建测试组 testgroup1，并手动添加重复 GID。"

  # 删除已有的测试组
  for group in testgroup1 testgroup2; do
    if getent group "$group" &>/dev/null; then
      echo "删除已存在的测试组 $group..."
      groupdel "$group"
    fi
  done

  # 创建第一个测试组
  local gid=$(get_next_available_gid)
  groupadd -g "$gid" testgroup1
  echo "已创建测试组 testgroup1，GID 为 $gid。"

  # 手动向 /etc/group 添加重复 GID
  echo "testgroup2:x:$gid:" >> /etc/group
  echo "已手动向 /etc/group 添加重复 GID $gid。"

  # 执行修复
  fix_duplicate_gids

  # 验证修复结果
  local gid1=$(getent group testgroup1 | cut -d: -f3)
  local gid2=$(getent group testgroup2 | cut -d: -f3)

  if [[ "$gid1" != "$gid2" ]]; then
    echo "自测成功: 重复的 GID 已成功修复。"
    groupdel testgroup1
    sed -i "/^testgroup2:/d" /etc/group
    return 0
  else
    echo "自测失败: GID 修复不正确。"
    return 1
  fi
}

# 修复重复 GID 的函数
fix_duplicate_gids() {
  local duplicate_gids=$(awk -F':' '{print $3}' /etc/group | sort | uniq -d)

  if [ -n "$duplicate_gids" ]; then
    echo "发现重复的 GID: $duplicate_gids，开始修复..."
    for gid in $duplicate_gids; do
      local groups=($(awk -F':' -v gid="$gid" '$3 == gid {print $1}' /etc/group))

      # 保留第一个组的 GID，修改其余组的 GID
      for i in "${!groups[@]}"; do
        group="${groups[$i]}"
        if [[ "$i" -eq 0 ]]; then
          echo "保留组 $group 的 GID 为 $gid。"
        else
          local new_gid=$(get_next_available_gid)
          echo "修复: 修改组 $group 的 GID 为 $new_gid..."
          groupmod -g "$new_gid" "$group"
          if [[ $? -eq 0 ]]; then
            echo "修复成功: 已为组 $group 分配新的 GID $new_gid。"
          else
            echo "修复失败: 无法修改组 $group 的 GID。"
            return 1
          fi
        fi
      done
    done
  else
    echo "所有 GID 均唯一，无需修复。"
  fi
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_duplicate_gids; then
  echo "修复完成: 所有 GID 已正确设置为唯一。"
  exit 0
else
  echo "修复失败: 部分 GID 未能正确设置。"
  exit 1
fi


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
# Description: Security Baseline Fix Script for 2.1.7
#
# #######################################################################################

#!/bin/bash

# 功能说明:
# 本脚本用于修复 /etc/passwd 中的用户组在 /etc/group 中不存在的问题。
# 如果找到缺失的组，则会自动添加到 /etc/group 中，确保系统的用户组一致性。
# 支持 --self-test 参数，用于验证修复逻辑。

# 参数解析函数，支持 --self-test 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [--self-test]"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试用户 testuser 并删除其组，以模拟错误场景。"

  # 检查是否存在同名用户，如果有则先删除
  if id testuser &>/dev/null; then
    echo "删除已存在的测试用户 testuser..."
    userdel -r testuser
  fi

  # 创建测试用户及其组
  useradd testuser
  groupdel testuser
  echo "已删除 testuser 的组，开始修复..."

  # 执行修复
  fix_missing_groups

  # 验证修复结果
  if getent group testuser &>/dev/null; then
    echo "自测成功: 缺失的组 testuser 已成功恢复。"
    userdel -r testuser
    return 0
  else
    echo "自测失败: 组 testuser 未正确恢复。"
    return 1
  fi
}

# 修复缺失的组函数
fix_missing_groups() {
  # 遍历 /etc/passwd 中所有用户的 GID，确保组存在于 /etc/group 中
  grep -E -v '^(halt|sync|shutdown)' "/etc/passwd" | \
  awk -F ":" '($7 != "/bin/false" && $7 != "/sbin/nologin") {print $1, $4}' | while read user gid; do
    if ! getent group "$gid" &>/dev/null; then
      echo "修复: GID $gid 不存在，正在创建对应的组..."
      groupadd -g "$gid" "$user"
      if [[ $? -eq 0 ]]; then
        echo "修复成功: 已为用户 $user 创建组 $user，GID 为 $gid。"
      else
        echo "修复失败: 无法为 GID $gid 创建组。"
        return 1
      fi
    fi
  done
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_missing_groups; then
  echo "修复完成: 所有用户的组已正确设置。"
  exit 0
else
  echo "修复失败: 部分用户的组未能正确设置。"
  exit 1
fi


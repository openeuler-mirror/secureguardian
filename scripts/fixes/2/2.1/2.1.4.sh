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
# Description: Security Baseline Fix Script for 2.1.4
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于修复系统中存在 UID 为 0 的非 root 账号的问题。
# 如果检测到 UID 为 0 的非 root 账号，会为其分配新的唯一 UID。
# 支持 --self-test 参数，用于验证修复逻辑。

# 默认例外用户列表
EXCEPTIONS=("root")

# 参数解析函数，支持 --self-test 和 -e 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a custom_exceptions <<< "$2"
        EXCEPTIONS+=("${custom_exceptions[@]}")
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e 账号列表] [--self-test]"
        echo "  -e: 指定例外账号列表，多个账号用逗号分隔"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 获取系统中未占用的最小可用 UID
get_next_available_uid() {
  local uid=1000  # 从 1000 开始，因为通常系统用户 UID 小于 1000
  while getent passwd "$uid" &>/dev/null; do
    uid=$((uid + 1))
  done
  echo "$uid"
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试用户 testuser，并手动修改其 UID 为 0。"

  # 检查是否存在同名用户，如果有则先删除
  if id testuser &>/dev/null; then
    echo "删除已存在的测试用户 testuser..."
    userdel -r testuser
  fi

  # 动态获取一个可用的 UID 来创建测试用户
  next_uid=$(get_next_available_uid)
  echo "使用 UID $next_uid 创建测试用户 testuser。"
  
  # 创建测试用户
  useradd -u "$next_uid" testuser
  if [[ $? -ne 0 ]]; then
    echo "自测失败: 无法创建测试用户 testuser。"
    return 1
  fi

  # 手动修改 /etc/passwd，将 testuser 的 UID 修改为 0
  sed -i "s/^testuser:x:$next_uid:/testuser:x:0:/" /etc/passwd
  echo "成功将 testuser 的 UID 修改为 0，开始修复..."

  # 执行修复
  fix_uid_zero_accounts

  # 验证修复结果
  local uid=$(id -u testuser 2>/dev/null)
  if [[ "$uid" != "0" ]]; then
    echo "自测成功: 账号 testuser 的 UID 已成功修改。"
    userdel -r testuser
    return 0
  else
    echo "自测失败: 账号 testuser 的 UID 仍为 0。"
    return 1
  fi
}

# 修复 UID 为 0 的非 root 账号
fix_uid_zero_accounts() {
  local uid_zero_accounts=$(awk -F':' '{if ($3 == 0) print $1}' /etc/passwd)

  for account in $uid_zero_accounts; do
    if [[ ! " ${EXCEPTIONS[@]} " =~ " ${account} " ]]; then
      echo "修复: 为账号 $account 分配新的 UID..."
      new_uid=$(get_next_available_uid)
      sed -i "s/^$account:x:0:/$account:x:$new_uid:/" /etc/passwd

      if [[ $? -eq 0 ]]; then
        echo "修复成功: 账号 $account 的 UID 已修改为 $new_uid。"
      else
        echo "修复失败: 无法修改账号 $account 的 UID。"
        return 1
      fi
    fi
  done
  return 0
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_uid_zero_accounts; then
  echo "修复完成: 所有非 root 的 UID 为 0 账号已被修复。"
  exit 0
else
  echo "修复失败: 无法修复所有非 root 的 UID 为 0 账号。"
  exit 1
fi


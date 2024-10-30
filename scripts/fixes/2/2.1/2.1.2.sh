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
# 功能说明:
# 本脚本用于检查并删除系统中的未使用账号，以减少攻击面。
# 支持通过参数指定例外账号，并提供自测模式确保逻辑正确。

# 默认排除的账号列表
EXCLUDE_ACCOUNTS="root,sync,halt,shutdown"
SELF_TEST=false

# 参数解析函数，支持短选项和长选项
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        EXCLUDE_ACCOUNTS+=",${2}"  # 添加用户指定的例外账号
        shift 2
        ;;
      --self-test)
        SELF_TEST=true  # 启用自测模式
        shift
        ;;
      *)
        echo "使用方法: $0 [-e 用户列表] [--self-test]"
        echo "  -e: 指定例外账号，多个账号用逗号分隔"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 解析传入的参数
parse_arguments "$@"

# 将例外账号字符串转换为数组
IFS=',' read -r -a exclude_accounts_array <<< "$EXCLUDE_ACCOUNTS"

# 初始化未使用账号列表
unused_accounts=()

# 检查未使用的账号
check_unused_accounts() {
  accounts=$(awk -F ":" '{if ($7 != "/sbin/nologin" && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") print $1}' /etc/passwd)

  for account in $accounts; do
    if [[ ! " ${exclude_accounts_array[*]} " =~ " ${account} " ]]; then
      if ! pgrep -u "$account" > /dev/null 2>&1; then
        unused_accounts+=("$account")
      fi
    fi
  done
}

# 删除未使用账号及其文件
delete_unused_accounts() {
  for account in "${unused_accounts[@]}"; do
    echo "正在删除账号: $account"
    find / -user "$account" -exec rm -rf {} \; 2>/dev/null
    userdel -r "$account"
    if [[ $? -eq 0 ]]; then
      echo "删除成功: 账号 $account 及其文件已被删除。"
    else
      echo "删除失败: 无法删除账号 $account 或其文件。"
      return 1
    fi
  done
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试账号 testuser。"
  useradd testuser
  usermod -s /bin/bash testuser

  check_unused_accounts
  delete_unused_accounts

  if id testuser &>/dev/null; then
    echo "自测失败: 账号 testuser 未能正确删除。"
    return 1
  else
    echo "自测成功: 账号 testuser 已正确删除。"
    return 0
  fi
}

# 检查是否启用自测模式
if [[ "$SELF_TEST" == true ]]; then
  echo "正在进入自测模式 (--self-test)..."
  self_test
  exit $?
fi

# 检查未使用的账号并自动删除
check_unused_accounts
if [ ${#unused_accounts[@]} -eq 0 ]; then
  echo "检查通过：不存在未使用的账号。"
  exit 0
else
  delete_unused_accounts
  exit $?
fi



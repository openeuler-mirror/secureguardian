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
# Description: Security Baseline Check Script for 2.1.9
#
# #######################################################################################

# 初始化例外账号数组
exceptions=()

# 解析命令行参数
while getopts "e:" opt; do
  case ${opt} in
    e )
      IFS=',' read -r -a exceptions <<< "${OPTARG}"
      ;;
    \? )
      echo "使用方法: $0 [-e 账号名1,账号名2,...]"
      exit 1
      ;;
  esac
done

# 检查账号名唯一性的函数
check_account_uniqueness() {
  # 检索/etc/passwd中的账号名并检查是否唯一
  local duplicate_accounts=$(awk -F':' '{print $1}' /etc/passwd | sort | uniq -d)

  for account in $duplicate_accounts; do
    # 检查账号是否在例外列表中
    if [[ " ${exceptions[@]} " =~ " ${account} " ]]; then
      # 如果账号在例外列表中，忽略这个账号
      echo "例外账号 $account 被忽略。"
    else
      # 如果账号不在例外列表中，报告重复账号
      echo "检测失败: 账号 $account 不唯一。"
      return 1
    fi
  done

  echo "检测成功: 所有账号名唯一。"
  return 0
}

# 调用检查函数
if check_account_uniqueness; then
  exit 0
else
  exit 1
fi


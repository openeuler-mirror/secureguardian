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
# Description: Security Baseline Check Script for 2.1.2
#
# #######################################################################################

# 默认排除的账号（自动排除nologin和bin/false账号，同时保留root为默认排除项）
EXCLUDE_ACCOUNTS="root sync halt shutdown"

# 接收并解析外部参数
while getopts "e:" opt; do
  case $opt in
    e) EXCLUDE_ACCOUNTS+=",${OPTARG}";;  # 通过逗号分隔，添加到排除列表
    \?) echo "无效选项: -$OPTARG" >&2; exit 1;;
  esac
done

# 分割字符串为数组，准备排除账号列表
IFS=',' read -r -a exclude_accounts_array <<< "$EXCLUDE_ACCOUNTS"

# 初始化未使用账号列表
unused_accounts=()

# 定义检查函数
check_unused_accounts() {
  # 通过awk获取不包含/sbin/nologin和/usr/sbin/nologin以及/bin/false shell的账号
  accounts=$(awk -F ":" '{if ($7 != "/sbin/nologin" && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") print $1}' /etc/passwd)

  # 循环检查每个账号
  for account in $accounts; do
    # 检查账号是否在排除列表中
    if [[ ! " ${exclude_accounts_array[*]} " =~ " ${account} " ]]; then
      # 检查该账号是否有属于其的进程
      if ! pgrep -u "$account" > /dev/null 2>&1; then
        unused_accounts+=("$account")  # 添加到未使用账号列表
      fi
    fi
  done
}

# 调用检查函数
check_unused_accounts

# 输出结果
if [ ${#unused_accounts[@]} -eq 0 ]; then
  echo "检查通过，不存在未使用的账号。"
  exit 0
else
  echo "检测失败: 发现可能未使用的账号：${unused_accounts[*]}"
  exit 1
fi


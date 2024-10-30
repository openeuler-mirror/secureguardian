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
# Description: Security Baseline Fix Script for 2.1.1
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于检查并修复无需登录的账号，将不应登录的账号的 shell 设置为 /sbin/nologin 或 /bin/false，减少攻击面。
# 支持指定例外账号，并提供自测功能确保修复逻辑的正确性。

# 备份原有配置文件
backup_file="/etc/passwd.bak.$(date +%F_%T)"
cp /etc/passwd "$backup_file"
echo "已备份 /etc/passwd 至 $backup_file"

# 默认例外账户
EXCEPTIONS=("root" "sync" "shutdown" "halt")

# 修复无需登录能力的账号
fix_non_login_accounts() {
  # 获取所有允许登录的账号
  login_accounts=$(grep -vE "/sbin/nologin|/bin/false" /etc/passwd | awk -F':' '{print $1}')

  # 遍历每个允许登录的账号
  for account in $login_accounts; do
    # 检查是否为例外账号
    if printf '%s\n' "${EXCEPTIONS[@]}" | grep -q "^$account$"; then
      echo "例外账号 $account 不修复。"
      continue
    fi

    # 检查账号是否已锁定
    lock_status=$(passwd -S "$account" | awk '{print $2}')
    if [[ "$lock_status" == "L" || "$lock_status" == "LK" ]]; then
      echo "账号 $account 已锁定，无需修复。"
      continue
    fi

    # 检查并修复 shell 设置
    shell=$(grep "^$account:" /etc/passwd | cut -d: -f7)
    if [[ "$shell" != "/sbin/nologin" && "$shell" != "/bin/false" ]]; then
      usermod -s /sbin/nologin "$account" || usermod -s /bin/false "$account"
      if [[ $? -eq 0 ]]; then
        echo "修复成功: 禁用 $account 的登录能力。"
      else
        echo "修复失败: 无法禁用 $account 的登录能力。"
        return 1
      fi
    fi
  done

  echo "修复完成: 所有不应登录的账号均已禁用登录能力。"
  return 0
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试账户 testuser。"
  useradd testuser
  usermod -s /bin/bash testuser

  fix_non_login_accounts

  result=$(grep "^testuser:" /etc/passwd | cut -d: -f7)
  if [[ "$result" == "/sbin/nologin" || "$result" == "/bin/false" ]]; then
    echo "自测成功: 账号 testuser 的登录能力已禁用。"
    userdel testuser
    return 0
  else
    echo "自测失败: 账号 testuser 未正确禁用。"
    userdel testuser
    return 1
  fi
}

# 参数解析函数，支持长短选项
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a CUSTOM_EXCEPTIONS <<< "$2"
        EXCEPTIONS+=("${CUSTOM_EXCEPTIONS[@]}")
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e 用户列表] [--self-test]"
        echo "  -e: 指定例外用户列表，多个用户用逗号分隔"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 解析传入的参数
parse_arguments "$@"

# 调用修复函数并处理返回值
if fix_non_login_accounts; then
  exit 0
else
  exit 1
fi


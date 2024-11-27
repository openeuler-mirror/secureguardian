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
# Description: Security Baseline Fix Script for 2.2.11
#
# #######################################################################################


# 功能说明:
# 本脚本用于确保指定用户在首次登录时强制修改口令。
# 仅在检测到用户从未登录的情况下，将口令设置为过期。支持通过参数指定用户，默认排除 root 账户。

# 定义文件路径
shadow_file="/etc/shadow"
passwd_file="/etc/passwd"

# 备份 /etc/shadow 文件
backup_shadow_file() {
  cp "$shadow_file" "${shadow_file}.bak.$(date +%F_%T)"
  echo "已备份 $shadow_file 至 ${shadow_file}.bak.$(date +%F_%T)"
}

# 强制指定用户首次登录时修改口令
force_password_change_for_user() {
  local username="$1"

  # 检查用户是否存在
  if ! id "$username" &>/dev/null; then
    echo "错误: 用户 $username 不存在。"
    return 1
  fi

  # 排除 root 和无登录权限的用户
  local shell
  shell=$(getent passwd "$username" | cut -d: -f7)
  if [[ "$username" == "root" || "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" || "$shell" == "/usr/sbin/nologin" ]]; then
    echo "跳过: 用户 $username 不需要设置口令过期。"
    return 0
  fi

  # 检查用户是否从未登录过
  if last -w "$username" | grep -q "$username"; then
    echo "跳过: 用户 $username 已登录过，不需设置口令过期。"
    return 0
  fi

  # 设置用户口令过期
  passwd -e "$username" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "已设置账号 $username 的口令过期，下次登录时将强制修改口令。"
    return 0
  else
    echo "设置失败: 无法将账号 $username 的口令设为过期。"
    return 1
  fi
}

# 自测功能，模拟修复场景
self_test() {
  echo "自测: 创建测试用户 testuser 并设置其首次登录修改口令。"
  useradd testuser
  
  force_password_change_for_user "testuser"

  # 检查模拟用户的过期设置
  if grep "^testuser:" "$shadow_file" | cut -d: -f3 | grep -q "^0$"; then
    echo "自测成功: testuser 的口令已设为过期。"
    userdel testuser
    return 0
  else
    echo "自测失败: 未正确设置 testuser 的口令过期状态。"
    userdel testuser
    return 1
  fi
}

# 参数解析
parse_arguments() {
  local specified_user=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user|-u)
        specified_user="$2"
        shift 2
        ;;
      --self-test|-s)
        self_test
        exit $?
        ;;
      /?)
        echo "使用方法: $0 [--user 用户名 | -u 用户名] [--self-test | -s]"
        exit 0
        ;;
      *)
        echo "未知选项: $1"
        exit 1
        ;;
    esac
  done

  # 如果指定了用户，则调用修复函数
  if [[ -n "$specified_user" ]]; then
    force_password_change_for_user "$specified_user"
  else
    echo "错误: 请使用 --user 指定一个用户。"
    exit 1
  fi
}

# 执行参数解析
parse_arguments "$@"

# 返回成功状态
exit 0


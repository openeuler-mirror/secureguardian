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
# Description: Security Baseline Check Script for 2.2.10
#
# #######################################################################################

# 定义服务文件路径
rescue_service="/usr/lib/systemd/system/rescue.service"
emergency_service="/usr/lib/systemd/system/emergency.service"

# 函数：检查单用户模式是否设置了口令保护
check_single_user_mode_password_protection() {
  local fail=0

  # 使用正则表达式检查rescue.service配置
  if ! grep -Eq "ExecStart=\s*-/usr/lib/systemd/systemd-sulogin-shell\s+rescue" "$rescue_service"; then
    echo "检测失败：rescue.service未正确配置使用systemd-sulogin-shell进行登录。"
    fail=1
  else
    echo "检测成功:rescue.service已正确配置使用systemd-sulogin-shell。"
  fi

  # 使用正则表达式检查emergency.service配置
  if ! grep -Eq "ExecStart=\s*-/usr/lib/systemd/systemd-sulogin-shell\s+emergency" "$emergency_service"; then
    echo "检测失败：emergency.service未正确配置使用systemd-sulogin-shell进行登录。"
    fail=1
  else
    echo "检测成功:emergency.service已正确配置使用systemd-sulogin-shell。"
  fi

  return $fail
}

# 主函数
main() {
  check_single_user_mode_password_protection
  if [ $? -ne 0 ]; then
    exit 1  # 存在配置不符合要求
  else
    exit 0  # 所有检查均通过
  fi
}

main


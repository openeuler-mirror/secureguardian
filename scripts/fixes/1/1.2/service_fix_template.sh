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
# Description: Security Baseline Fix Script Template for Disabling Unnecessary Services
#
# #######################################################################################

# 功能说明:
# 本脚本用于禁用不符合安全基线要求的服务，如debug-shell等，确保系统安全。

# 默认配置
SERVICE_NAME="$1"

# 安全性检查: 确保不会禁用关键系统服务
safety_check() {
  local critical_services=("sshd" "systemd" "network" "crond")

  for service in "${critical_services[@]}"; do
    if [[ "$SERVICE_NAME" == "$service" ]]; then
      echo "安全检查失败: $SERVICE_NAME 是关键服务，不能禁用。"
      return 1
    fi
  done

  return 0
}

# 禁用相关的socket服务
disable_socket() {
  local socket_service="${SERVICE_NAME}.socket"
  if systemctl list-unit-files | grep -q "^${socket_service}"; then
    echo "正在禁用$socket_service..."
    systemctl --now disable "$socket_service"
    if [[ $? -ne 0 ]]; then
      echo "修复失败: 无法禁用$socket_service。"
      return 1
    else
      echo "修复成功: 已成功禁用$socket_service。"
    fi
  fi
  return 0
}

# 修复方法: 禁用不符合要求的服务
fix_unwanted_service() {
  # 检查服务是否已禁用
  if systemctl is-enabled "$SERVICE_NAME" | grep -q "disabled"; then
    echo "$SERVICE_NAME 服务已禁用，无需操作。"
    # 检查并禁用相关的socket服务
    disable_socket
    if [[ $? -ne 0 ]]; then
      return 1  # 禁用socket服务失败，返回错误
    fi
    return 0  # 服务和socket都已禁用，返回成功
  fi

  echo "正在禁用$SERVICE_NAME服务..."

  # 禁用服务并立即停止
  systemctl --now disable "$SERVICE_NAME"

  if [[ $? -ne 0 ]]; then
    echo "修复失败: 无法禁用$SERVICE_NAME服务。"
    return 1
  else
    echo "修复成功: 已成功禁用$SERVICE_NAME服务。"
    # 禁用相关的 socket 服务
    disable_socket
    if [[ $? -ne 0 ]]; then
      return 1  # 禁用socket服务失败，返回错误
    fi
    return 0
  fi
}

# 进行安全性检查
safety_check
if [[ $? -ne 0 ]]; then
  exit 1
fi

# 调用修复函数并处理返回值
fix_unwanted_service
exit $?


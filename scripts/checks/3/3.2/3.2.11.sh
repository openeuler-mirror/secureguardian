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
# Description: Security Baseline Check Script for 3.2.11
#
# #######################################################################################

# 检查服务是否安装
check_service_installed() {
  local service_name=$1
  systemctl list-unit-files | grep -q "^$service_name.service"
}

# 检查服务状态
check_service_status() {
  local service_name=$1
  local expected_status=$2
  local service_status=$(systemctl is-active $service_name 2>/dev/null)
  
  if [[ $service_status != "$expected_status" ]]; then
    echo "检测失败: 服务 $service_name 状态为 $service_status，预期为 $expected_status"
    return 1
  else
    echo "服务 $service_name 状态正常 ($service_status)"
  fi
  return 0
}

# 主检查函数
check_firewall_services() {
  local failed=0

  # 检查 nftables 必须是活跃的
  if check_service_installed "nftables"; then
    check_service_status "nftables" "active" || let failed++
  else
    echo "检测失败: 服务 nftables 未安装，必须安装并启用"
    return 1
  fi

  # 检查 firewalld 必须是未激活的，如果已安装
  if check_service_installed "firewalld"; then
    check_service_status "firewalld" "inactive" || let failed++
  fi

  # 检查 iptables 必须是未激活的，如果已安装
  if check_service_installed "iptables"; then
    check_service_status "iptables" "inactive" || let failed++
  fi

  return $failed
}

# 调用主检查函数并处理返回值
if check_firewall_services; then
  echo "所有防火墙服务状态检查通过。"
  exit 0
else
  echo "某些防火墙服务状态检查未通过。"
  exit 1
fi


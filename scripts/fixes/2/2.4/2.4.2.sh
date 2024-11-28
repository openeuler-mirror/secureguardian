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
# Description: Security Baseline Check Script for 2.4.2
#
# #######################################################################################
# 功能说明:
# 本脚本用于检查并确保SELinux运行在强制(enforcing)模式。
# 如果未启用enforcing模式，将立即启用，并在配置文件中设置默认值。
# 支持 --self-test 选项以在测试环境中验证功能。

# 检查SELinux当前模式
get_current_selinux_mode() {
  getenforce
}

# 备份 /etc/selinux/config 文件
backup_selinux_config() {
  local config_file="/etc/selinux/config"
  cp "$config_file" "${config_file}.bak.$(date +%F_%T)"
  echo "已备份 $config_file 至 ${config_file}.bak.$(date +%F_%T)"
}

# 强制设置SELinux为enforcing模式
apply_selinux_enforcing() {
  local config_file="/etc/selinux/config"
  backup_selinux_config

  # 设置当前运行模式为 enforcing
  setenforce 1
  echo "当前SELinux模式已设置为 Enforcing。"

  # 更新 /etc/selinux/config 文件中的默认模式
  if grep -q "^SELINUX=" "$config_file"; then
    sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$config_file"
  else
    echo "SELINUX=enforcing" >> "$config_file"
  fi

  echo "$config_file 文件已更新：SELINUX 默认模式设置为 enforcing。"
}

# 自测功能，模拟SELinux enforcing设置
self_test() {
  echo "自测: 模拟SELinux配置并验证。"
  local test_file="/tmp/selinux_config_test"

  # 创建临时测试文件
  cp "/etc/selinux/config" "$test_file"
  local config_file="$test_file"

  # 临时设置并验证enforcing模式
  setenforce 1
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$config_file"

  # 检查设置是否正确
  if [[ $(getenforce) == "Enforcing" && $(grep "^SELINUX=" "$config_file" | cut -d'=' -f2 | tr -d ' ') == "enforcing" ]]; then
    echo "自测成功：SELinux enforcing 模式配置正确。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：SELinux enforcing 模式配置未正确应用。"
    rm "$test_file"
    return 1
  fi
}

# 检查参数是否为 --self-test
if [[ "$1" == "--self-test" ]]; then
  self_test
  exit $?
fi

# 检查当前模式并执行修复
if [[ $(get_current_selinux_mode) != "Enforcing" || $(grep "^SELINUX=" /etc/selinux/config | cut -d'=' -f2 | tr -d ' ') != "enforcing" ]]; then
  apply_selinux_enforcing
else
  echo "SELinux 已经配置为 enforcing 模式，无需更改。"
fi

# 返回成功状态
exit 0


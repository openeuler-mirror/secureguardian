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
# Description: Security Baseline Check Script for 2.3.4
#
# #######################################################################################
# 功能说明:
# 本脚本用于确保SSH的Banner配置正确，默认设置为 /etc/issue.net。
# 如果未配置，将自动修复并重启sshd服务。
# 支持 --self-test 选项以在测试环境中验证功能。

# 默认Banner路径
expected_banner_path=${1:-"/etc/issue.net"}
ssh_config_file="/etc/ssh/sshd_config"

# 备份SSH配置文件
backup_ssh_config() {
  cp "$ssh_config_file" "${ssh_config_file}.bak.$(date +%F_%T)"
  echo "已备份 $ssh_config_file 至 ${ssh_config_file}.bak.$(date +%F_%T)"
}

# 应用Banner配置
apply_banner_configuration() {
  backup_ssh_config

  # 检查并设置Banner路径
  if grep -qiP "^\s*Banner\s+" "$ssh_config_file"; then
    sed -i "s|^\s*Banner\s+.*|Banner $expected_banner_path|" "$ssh_config_file"
  else
    echo "Banner $expected_banner_path" >> "$ssh_config_file"
  fi

  echo "$ssh_config_file 中的Banner配置已更新为 $expected_banner_path。"
  # 重启sshd服务使更改生效
  systemctl restart sshd
  echo "sshd服务已重启。"
}

# 自测功能，模拟修复场景
self_test() {
  echo "自测: 模拟Banner配置并验证。"
  local test_file="/tmp/sshd_config_test"

  # 创建临时测试文件
  cp "$ssh_config_file" "$test_file"
  
  # 临时设置配置文件路径为测试文件
  ssh_config_file="$test_file"
  apply_banner_configuration

  # 检查设置是否正确
  if grep -qiP "^\s*Banner\s+$expected_banner_path" "$test_file"; then
    echo "自测成功：测试文件中的Banner配置正确。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：Banner配置未正确应用。"
    rm "$test_file"
    return 1
  fi
}

# 检查参数是否为 --self-test
if [[ "$1" == "--self-test" ]]; then
  self_test
  exit $?
fi

# 执行修复
apply_banner_configuration

# 返回成功状态
exit 0


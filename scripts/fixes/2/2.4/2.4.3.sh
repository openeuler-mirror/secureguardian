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
# Description: Security Baseline Check Script for 2.4.3
#
# #######################################################################################
# 功能说明:
# 本脚本用于确保SELinux的策略配置为targeted，确保系统的安全性。
# 如果未配置为targeted策略，将自动修复，并在重启后应用更改。
# 支持 --self-test 选项以在测试环境中验证功能。

# 默认SELinux策略类型
default_policy_type="targeted"
config_file="/etc/selinux/config"

# 备份SELinux配置文件
backup_selinux_config() {
    cp "$config_file" "${config_file}.bak.$(date +%F_%T)"
    echo "已备份 $config_file 至 ${config_file}.bak.$(date +%F_%T)"
}

# 设置SELinux策略为targeted
apply_selinux_policy() {
    backup_selinux_config

    # 更新 /etc/selinux/config 中的策略类型
    if grep -q "^SELINUXTYPE=" "$config_file"; then
        sed -i "s/^SELINUXTYPE=.*/SELINUXTYPE=$default_policy_type/" "$config_file"
    else
        echo "SELINUXTYPE=$default_policy_type" >> "$config_file"
    fi
    echo "$config_file 文件中的SELINUXTYPE已设置为 $default_policy_type。"

    # 创建 /.autorelabel 文件，确保系统重启后自动重新标记
    touch /.autorelabel
    echo "已创建 /.autorelabel 文件。请重启系统以应用更改。"
}

# 自测功能，模拟SELinux策略配置
self_test() {
    echo "自测: 模拟SELinux策略配置并验证。"
    local test_file="/tmp/selinux_config_test"

    # 创建临时测试文件
    cp "$config_file" "$test_file"

    # 临时更新策略配置文件路径
    config_file="$test_file"
    apply_selinux_policy

    # 验证设置是否正确
    if grep -q "^SELINUXTYPE=$default_policy_type" "$test_file"; then
        echo "自测成功：测试文件中的SELINUX策略类型配置正确。"
        rm "$test_file"
        return 0
    else
        echo "自测失败：SELINUX策略类型配置未正确应用。"
        rm "$test_file"
        return 1
    fi
}

# 检查参数是否为 --self-test
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
fi

# 检查当前策略配置并执行修复
current_policy_type=$(grep -oP "^\s*SELINUXTYPE\s*=\s*\K.*" "$config_file" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ "$current_policy_type" != "$default_policy_type" ]]; then
    echo "SELinux策略类型设置不正确。当前策略类型：$current_policy_type，期望策略类型：$default_policy_type。"
    apply_selinux_policy
else
    echo "SELinux策略已正确配置为 $default_policy_type。"
fi

# 返回成功状态
exit 0


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
# Description: Security Baseline Check Script for 3.2.1
#
# #######################################################################################
# 确保启用 firewalld 服务并禁用 iptables 和 nftables 服务
#
# 功能说明：
# - 启用 firewalld 服务并设置为开机自启。
# - 禁用 iptables 和 nftables 服务，并确保设置永久生效。
# - 提供自测功能，保留接口，直接返回成功。

# 启用 firewalld 服务
enable_firewalld() {
    echo "正在启用 firewalld 服务..."
    systemctl start firewalld
    systemctl enable firewalld

    if systemctl is-active firewalld &>/dev/null; then
        echo "firewalld 服务已成功启用并设置为开机自启。"
    else
        echo "错误: 无法启用 firewalld 服务，请手动检查。"
        exit 1
    fi
}

# 禁用 iptables 和 nftables 服务
disable_other_firewalls() {
    local services=("iptables" "nftables")

    for service in "${services[@]}"; do
        echo "正在禁用 $service 服务..."
        systemctl stop "$service"
        systemctl disable "$service"

        if ! systemctl is-active "$service" &>/dev/null; then
            echo "$service 服务已成功禁用并设置为不随开机启动。"
        else
            echo "错误: 无法禁用 $service 服务，请手动检查。"
            exit 1
        fi
    done
}

# 自测功能
self_test() {
    echo "自测接口保留，直接返回成功。"
    return 0
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            echo "使用方法: $0 [--self-test]"
            exit 1
            ;;
    esac
done

# 主修复逻辑
enable_firewalld
disable_other_firewalls

echo "修复完成：firewalld 服务已启用，iptables 和 nftables 服务已禁用。"
exit 0


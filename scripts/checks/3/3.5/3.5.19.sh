#!/bin/bash

# 功能说明：
# 此脚本用于检查系统的 ARP 代理设置，以确保 ARP 代理功能被正确禁用。
# 用户可以通过外部参数自定义期望的配置值，如果未指定参数，默认值为0（禁用ARP代理）。

# 获取脚本参数，如果未指定则使用默认值0
expected_value=${1:-0}

check_arp_proxy() {
    # 检查所有接口的ARP代理设置
    local all_proxy_arp=$(sysctl -n net.ipv4.conf.all.proxy_arp)
    local default_proxy_arp=$(sysctl -n net.ipv4.conf.default.proxy_arp)

    # 检查当前值是否等于期望值
    if [[ "$all_proxy_arp" -eq "$expected_value" && "$default_proxy_arp" -eq "$expected_value" ]]; then
        echo "检测成功: ARP代理设置已被正确配置。"
        return 0
    else
        echo "检测失败: ARP代理设置未正确配置。"
        return 1
    fi
}

# 调用检测函数并根据返回值决定脚本退出状态
if check_arp_proxy; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


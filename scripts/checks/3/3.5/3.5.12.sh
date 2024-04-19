#!/bin/bash

# 功能说明：
# 此脚本用于检查系统内核参数是否已正确设置以禁止IP转发。
# 这有助于防止该系统被用作未授权的路由器。

check_ip_forwarding() {
    # 检查IPv4转发设置
    local ipv4_forward=$(sysctl -n net.ipv4.ip_forward)
    # 检查IPv6转发设置
    local ipv6_forward=$(sysctl -n net.ipv6.conf.all.forwarding)

    # 判断转发是否被禁用（应设置为0）
    if [[ "$ipv4_forward" -eq 0 && "$ipv6_forward" -eq 0 ]]; then
        echo "检测成功: 系统已正确设置以禁止IPv4和IPv6转发。"
        return 0
    else
        echo "检测失败: IP转发未被禁用。当前IPv4转发设置：$ipv4_forward, IPv6转发设置：$ipv6_forward。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_ip_forwarding; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


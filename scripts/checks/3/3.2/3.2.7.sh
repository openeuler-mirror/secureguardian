#!/bin/bash

# 检查 IPv4 loopback 策略
check_ipv4_loopback_policy() {
    local ipv4_accept_found=$(iptables -L INPUT -v -n | grep -E "ACCEPT.*all.*lo.*0.0.0.0/0.*0.0.0.0/0")
    local ipv4_drop_found=$(iptables -L INPUT -v -n | grep -E "DROP.*all.*\*.*127.0.0.0/8.*0.0.0.0/0")

    if [[ -n "$ipv4_accept_found" && -n "$ipv4_drop_found" ]]; then
        echo "IPv4 策略配置正确。"
        ipv4_status=0
    else
        echo "检测失败: IPv4 策略配置不正确。"
        [[ -z "$ipv4_accept_found" ]] && echo "未正确配置 IPv4 的 ACCEPT 策略。"
        [[ -z "$ipv4_drop_found" ]] && echo "未正确配置 IPv4 的 DROP 策略。"
        ipv4_status=1
    fi
    return $ipv4_status
}

# 检查 IPv6 loopback 策略
check_ipv6_loopback_policy() {
    local ipv6_accept_found=$(ip6tables -L INPUT -v -n | grep -E "ACCEPT.*all.*lo.*::/0.*::/0")
    local ipv6_drop_found=$(ip6tables -L INPUT -v -n | grep -E "DROP.*all.*\*.*::1.*::/0")

    if [[ -n "$ipv6_accept_found" && -n "$ipv6_drop_found" ]]; then
        echo "IPv6 策略配置正确。"
        ipv6_status=0
    else
        echo "检测失败: IPv6 策略配置不正确。"
        [[ -z "$ipv6_accept_found" ]] && echo "未正确配置 IPv6 的 ACCEPT 策略。"
        [[ -z "$ipv6_drop_found" ]] && echo "未正确配置 IPv6 的 DROP 策略。"
        ipv6_status=1
    fi
    return $ipv6_status
}

# 主执行逻辑
check_ipv4_loopback_policy
ipv4_result=$?
check_ipv6_loopback_policy
ipv6_result=$?

if [[ $ipv4_result -eq 0 && $ipv6_result -eq 0 ]]; then
    echo "所有检查通过。"
    exit 0
else
    echo "至少一个检查未通过。"
    exit 1
fi


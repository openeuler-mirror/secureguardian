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
# Description: Security Baseline Check Script for 3.2.9
#
# #######################################################################################

# 默认设置
DEFAULT_PORTS=(22)  # 示例：默认检查 SSH 端口
DEFAULT_PROTOCOLS=("tcp")  # 示例：默认检查 TCP 协议

# 显示使用说明
show_usage() {
    echo "用法：$0 [-p <port1,port2,...>] [-P <protocol1,protocol2,...>] [-h]"
    echo "选项:"
    echo "  -p <ports>       指定要检查的端口列表，用逗号分隔"
    echo "  -P <protocols>   指定要检查的协议列表，用逗号分隔"
    echo "  -h               显示此帮助信息"
}

# 检查 IPv4 策略
check_ipv4_policy() {
    local ports=("$1")
    local protocols=("$2")
    local failure=0

    echo "检查 IPv4 策略:"
    for port in "${ports[@]}"; do
        for protocol in "${protocols[@]}"; do
            local rule=$(iptables -L OUTPUT -v -n | grep -E "$protocol.*spt:$port")
            if [[ -z "$rule" ]]; then
                echo "IPv4 没有为端口 $port 配置 $protocol 接受规则。"
                failure=1
            else
                echo "IPv4 已正确配置接受端口 $port 的 $protocol 请求。"
            fi
        done
    done

    # 检查默认策略
    local default_policy=$(iptables -L OUTPUT -n | grep "Chain OUTPUT" | awk '{print $4}' | tr -d '()' )
    if [[ "$default_policy" != "DROP" ]]; then
        echo "IPv4 的 OUTPUT 默认策略不是 DROP。当前策略为 $default_policy。"
        failure=1
    else
        echo "IPv4 的 OUTPUT 默认策略已设置为 DROP。"
    fi

    return $failure
}

# 检查 IPv6 策略
check_ipv6_policy() {
    local ports=("$1")
    local protocols=("$2")
    local failure=0

    echo "检查 IPv6 策略:"
    for port in "${ports[@]}"; do
        for protocol in "${protocols[@]}"; do
            local rule=$(ip6tables -L OUTPUT -v -n | grep -E "$protocol.*spt:$port")
            if [[ -z "$rule" ]]; then
                echo "IPv6 没有为端口 $port 配置 $protocol 接受规则。"
                failure=1
            else
                echo "IPv6 已正确配置接受端口 $port 的 $protocol 请求。"
            fi
        done
    done

    # 检查默认策略
    local default_policy=$(ip6tables -L OUTPUT -n | grep "Chain OUTPUT" | awk '{print $4}' | tr -d '()')
    if [[ "$default_policy" != "DROP" ]]; then
        echo "IPv6 的 OUTPUT 默认策略不是 DROP。当前策略为 $default_policy。"
        failure=1
    else
        echo "IPv6 的 OUTPUT 默认策略已设置为 DROP。"
    fi

    return $failure
}

# 解析命令行参数
while getopts ":p:P:h" opt; do
    case ${opt} in
        p ) IFS=',' read -r -a ports <<< "$OPTARG" ;;
        P ) IFS=',' read -r -a protocols <<< "$OPTARG" ;;
        h ) show_usage; exit 0 ;;
        \? ) show_usage; exit 1 ;;
    esac
done

# 使用默认值
ports=${ports:-${DEFAULT_PORTS[@]}}
protocols=${protocols:-${DEFAULT_PROTOCOLS[@]}}

# 执行检查
check_ipv4_policy "${ports[@]}" "${protocols[@]}"
ipv4_result=$?

check_ipv6_policy "${ports[@]}" "${protocols[@]}"
ipv6_result=$?

if [[ $ipv4_result -eq 0 && $ipv6_result -eq 0 ]]; then
    echo "检查成功:所有 IPv4 和 IPv6 的检查通过。"
    exit 0
else
    echo "检查失败:至少一个 IPv4 或 IPv6 的检查未通过。"
    exit 1
fi

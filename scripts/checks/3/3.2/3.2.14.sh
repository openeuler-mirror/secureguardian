#!/bin/bash

# 默认端口和协议
PORTS="22"  # 默认为22
PROTOCOLS="tcp"  # 默认协议为tcp

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-p ports] [-t protocols] [-h]"
    echo "  -p ports      指定要检查的一个或多个端口，用逗号分隔（默认为 '22'）"
    echo "  -t protocols  指定一个或多个协议，用逗号分隔（默认为 'tcp'）"
    echo "  -h            显示帮助信息"
}

# 解析命令行参数
while getopts ":p:t:h" opt; do
    case $opt in
        p) PORTS=$OPTARG ;;
        t) PROTOCOLS=$OPTARG ;;
        h) show_usage
           exit 0 ;;
        \?) show_usage
            exit 1 ;;
    esac
done

# 检查指定端口或服务是否开放
check_ports_open() {
    local ruleset=$(nft list ruleset)
    local failed=0

    IFS=','  # 设置内部字段分隔符为逗号，用于分隔端口和协议
    for protocol in $PROTOCOLS; do
        for port in $PORTS; do
            local match=$(echo "$ruleset" | awk -v port="$port" -v proto="$protocol" '
            $1 == "chain" && $2 == "input" {recording=1}
            recording && $1 == "}" {recording=0}
            recording && $0 ~ "dport " port " accept" && $0 ~ proto {found=1; exit}
            END {if (found) print "yes"; else print "no"}')

            if [ "$match" == "yes" ]; then
                echo "端口 $port 已正确配置为 ACCEPT 在 $protocol 协议上。"
            else
                echo "检测失败: 端口 $port 未在 $protocol 协议上配置为 ACCEPT。"
                failed=1
            fi
        done
    done

    return $failed
}

# 执行检查
if check_ports_open; then
    echo "检查成功:所有指定端口和协议的检查通过。"
    exit 0
else
    echo "检查失败:至少一个指定端口或协议的检查未通过。"
    exit 1
fi


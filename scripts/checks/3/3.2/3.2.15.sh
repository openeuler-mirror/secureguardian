#!/bin/bash

# 默认端口和协议
PORTS="22"  # 默认检查端口22
PROTOCOLS="tcp"  # 默认协议是tcp

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-p ports] [-t protocols] [-h]"
    echo "  -p ports      指定一个或多个端口，用逗号分隔（默认为 '22'）"
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

# 检查output链的端口和协议配置
check_output_config() {
    local ruleset=$(nft list ruleset)
    local failed=0

    IFS=',' read -ra PORTS_ARRAY <<< "$PORTS"
    IFS=',' read -ra PROTOCOLS_ARRAY <<< "$PROTOCOLS"
    
    for port in "${PORTS_ARRAY[@]}"; do
        for protocol in "${PROTOCOLS_ARRAY[@]}"; do
            local match=$(echo "$ruleset" | awk -v port="$port" -v proto="$protocol" '
            /chain output/ {recording=1} 
            recording && /}/ {recording=0}
            recording && $0 ~ "sport " port && $0 ~ proto && /accept/ {found=1; exit}
            END {if (found) print "yes"; else print "no"}')

            if [ "$match" == "yes" ]; then
                echo "在output链中，协议 $protocol 的源端口 $port 已正确配置为 ACCEPT。"
            else
                echo "检测失败: 在output链中，协议 $protocol 的源端口 $port 未配置为 ACCEPT。"
                failed=1
            fi
        done
    done

    return $failed
}

# 执行检查
if check_output_config; then
    echo "检查成功:所有指定的端口和协议的output链配置检查通过。"
    exit 0
else
    echo "检查失败:至少一个指定的端口或协议的output链配置检查未通过。"
    exit 1
fi


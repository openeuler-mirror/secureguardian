#!/bin/bash

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-s <service_name>]+"
    echo "示例：$0 -s firewalld -s iptables -s nftables"
    echo "不带选项时默认检查 firewalld、iptables 和 nftables。"
}

# 函数：检查服务状态
check_service_status() {
    local service_name=$1
    local status_output=$(systemctl is-active $service_name)

    if [[ $status_output == "active" ]]; then
        echo "$service_name 服务正在运行或已正确执行任务。"
        return 0
    else
        echo "$service_name 服务未运行。"
        return 1
    fi
}

# 默认服务
declare -a default_services=("firewalld" "iptables" "nftables")

# 解析命令行参数
declare -a services
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service)
            services+=("$2")
            shift; shift
            ;;
        /?|--help)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# 如果没有指定任何服务，使用默认值
if [ ${#services[@]} -eq 0 ]; then
    services=("${default_services[@]}")
fi

# 检查服务状态
active_count=0
for service in "${services[@]}"; do
    check_service_status "$service" && active_count=$((active_count + 1))
done

# 根据激活的服务数量检查是否通过测试
if [[ $active_count -eq 1 ]]; then
    echo "检查通过：只有一个防火墙服务正在运行。"
    exit 0
else
    echo "检查未通过：有 $active_count 个防火墙服务正在运行。"
    exit 1
fi


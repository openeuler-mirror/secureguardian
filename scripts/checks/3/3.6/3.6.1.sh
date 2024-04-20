#!/bin/bash

# 检查ntpd服务配置的函数
check_ntpd_config() {
    local config_file="${1:-/etc/ntp.conf}"  # 如果没有提供参数，则使用默认配置文件路径

    # 检查 ntpd 服务是否启动
    local service_status
    service_status=$(systemctl status ntpd | grep -E "Active:\s+active \(running\)" | grep -o "running")
    if [ "$service_status" != "running" ]; then
        echo "检测失败: ntpd服务未启动或不处于活动状态。"
        return 1
    fi

    # 检查 ntp.conf 文件中的 restrict 配置
    local restrict_config
    restrict_config=$(grep -E "^restrict" "$config_file" | grep -v '^#' | tr -s ' ')
    if [ -z "$restrict_config" ]; then
        echo "检测失败: /etc/ntp.conf 中未找到任何有效的 restrict 配置。"
        return 1
    fi

    # 检查 ntp.conf 文件中的 server 或 pool 配置
    local server_config
    server_config=$(grep -E "^(server|pool)" "$config_file" | grep -v '^#' | tr -s ' ')
    if [ -z "$server_config" ]; then
        echo "检测失败: /etc/ntp.conf 中未配置任何 NTP 服务器（server或pool）。"
        return 1
    fi

    # 所有检查通过
    echo "所有检查通过: ntpd 服务配置正确。"
    return 0
}

# 解析命令行参数并执行
while getopts ":c:?" opt; do
    case ${opt} in
        c )
            config_file="$OPTARG"
            ;;
        \? )
            echo "使用方式: $0 [-c <config_file>]"
            echo "参数:"
            echo "  -c <config_file>    指定 NTP 配置文件的路径。默认为 /etc/ntp.conf"
            exit 0
            ;;
        * )
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# 调用检查函数
if check_ntpd_config "$config_file"; then
    exit 0
else
    exit 1
fi


#!/bin/bash

# 定义检查chronyd服务配置的函数
check_chronyd_config() {
    local config_file="${1:-/etc/chrony.conf}"  # 如果未提供参数，则使用默认路径

    # 检查chronyd服务是否启动
    local service_status=$(systemctl is-active chronyd)
    if [ "$service_status" != "active" ]; then
        echo "检测失败: chronyd服务未启动。当前状态为：$service_status"
        return 1
    fi

    # 检查授时服务器是否已配置
    local server_config=$(grep -E "^(server|pool)" "$config_file" | grep -v '^#' | tr -s ' ')
    if [ -z "$server_config" ]; then
        echo "检测失败: 未在$config_file中配置授时服务器（server或pool）。"
        return 1
    fi

    echo "所有检查通过: chronyd服务配置正确。"
    return 0
}

# 提供帮助信息
show_usage() {
    echo "使用方式: $0 [-c <config_file>]"
    echo "  -c <config_file>  指定chrony配置文件的路径。默认为 /etc/chrony.conf"
}

# 解析命令行参数
while getopts ":c:?" opt; do
    case "$opt" in
        c)
            config_file="$OPTARG"
            ;;
        \?)
            show_usage
            exit 0
            ;;
        *)
            echo "无效选项: -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# 调用检查函数并处理返回值
if check_chronyd_config "$config_file"; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


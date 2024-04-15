#!/bin/bash

# 默认参数值
zone="public"
service=""
port=""

# 配置文件路径
config_file=""

# 函数：显示脚本使用说明
show_usage() {
    echo "用法: $0 [-z <zone>] [-s <service>] [-p <port>] [-f <config_file>]"
    echo "示例: $0 -z public -s ssh -p 22/tcp"
    echo "选项:"
    echo "  -z <zone>         设置防火墙区域 (默认为 'public')"
    echo "  -s <service>      指定要检测的服务"
    echo "  -p <port>         指定要检测的端口"
    echo "  -f <config_file>  指定配置文件路径"
    echo "                     配置文件应该包含以下格式的内容:"
    echo "                     zone,service,port"
    echo "                     public,ssh,22/tcp"
    echo "                     work,samba,80/tcp"
    echo "                     ..."
}

# 函数：检查指定区域是否开放了指定服务和端口
check_firewall_config() {
    local zone=$1
    local service=$2
    local port=$3
    
    # 获取指定区域的防火墙配置
    local firewall_config=$(firewall-cmd --zone=$zone --list-all)
    
    # 检查服务是否开放
    if [[ ! -z $service ]]; then
        if ! echo "$firewall_config" | grep -q "services:.*$service"; then
            echo "检测失败: 区域 $zone 未开放必需服务 $service。"
            return 1
        fi
    fi
    
    # 检查端口是否开放
    if [[ ! -z $port ]]; then
        if ! echo "$firewall_config" | grep -q "ports:.*$port"; then
            echo "检测失败: 区域 $zone 未开放必需端口 $port。"
            return 1
        fi
    fi
    
    return 0
}

# 函数：从配置文件中读取参数并检测防火墙配置
check_config_from_file() {
    local config_file=$1
    
    # 检查配置文件是否存在
    if [[ ! -f $config_file ]]; then
        echo "错误: 配置文件 '$config_file' 不存在。"
        return 1
    fi
    
    # 逐行读取配置文件并检测防火墙配置
    while IFS=',' read -r zone service port; do
        if ! check_firewall_config "$zone" "$service" "$port"; then
            return 1
        fi
    done < "$config_file"
    
    return 0
}

# 解析命令行参数
while getopts ":z:s:p:f:h" opt; do
    case $opt in
        z)
            zone=$OPTARG
            ;;
        s)
            service=$OPTARG
            ;;
        p)
            port=$OPTARG
            ;;
        f)
            config_file=$OPTARG
            ;;
        h)
            show_usage
            exit 0
            ;;
        :)
            echo "错误: 选项 '-$OPTARG' 需要参数。" >&2
            exit 1
            ;;
        \?)
            echo "错误: 未知选项 '-$OPTARG'。" >&2
            exit 1
            ;;
    esac
done

# 如果指定了配置文件，则从配置文件中读取参数并检测防火墙配置
if [[ ! -z $config_file ]]; then
    if ! check_config_from_file "$config_file"; then
        echo "至少有一个指定区域的配置检查未通过。"
        exit 1
    fi
else
    # 否则，检查指定区域是否开放了指定服务和端口
    if ! check_firewall_config "$zone" "$service" "$port"; then
        exit 1
    fi
fi

echo "所有指定区域的配置检查通过。"
exit 0


#!/bin/bash

# 默认配置文件路径
CONFIG_FILE="/etc/rsyslog.conf"
CONFIG_DIR="/etc/rsyslog.d"

# 显示帮助信息
usage() {
    echo "用法: $0 [-c 配置文件] [-d 配置目录]"
    echo "  -c  指定rsyslog主配置文件的路径（默认：/etc/rsyslog.conf）"
    echo "  -d  指定rsyslog配置目录的路径（默认：/etc/rsyslog.d）"
    echo "  -h  显示此帮助信息"
}

# 解析命令行参数
while getopts "c:d:h" opt; do
    case $opt in
        c) CONFIG_FILE=$OPTARG ;;
        d) CONFIG_DIR=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) echo "无效选项: -$OPTARG" >&2; exit 1 ;;
    esac
done

# 检查远程日志监听配置
check_remote_logging_config() {
    local fail=0
    local mod_load_tcp=$(grep -P '^\$ModLoad\s+imtcp' $CONFIG_FILE $CONFIG_DIR/*.conf | grep -v '^#')
    local mod_load_udp=$(grep -P '^\$ModLoad\s+ imudp' $CONFIG_FILE $CONFIG_DIR/*.conf | grep -v '^#')
    local input_tcp=$(grep -P '^\$InputTCPServerRun\s+[0-9]+' $CONFIG_FILE $CONFIG_DIR/*.conf | grep -v '^#')
    local input_udp=$(grep -P '^\$InputUDPServerRun\s+[0-9]+' $CONFIG_FILE $CONFIG_DIR/*.conf | grep -v '^#')

    if [ -z "$mod_load_tcp" ] && [ -z "$mod_load_udp" ]; then
        echo "检测失败: 未在配置文件中配置TCP或UDP模块加载。"
        fail=1
    else
        if [ -n "$mod_load_tcp" ] && [ -z "$input_tcp" ]; then
            echo "检测失败: TCP模块已加载，但未配置监听端口。"
            fail=1
        elif [ -n "$mod_load_tcp" ]; then
            echo "检测成功: 已配置TCP监听。"
        fi

        if [ -n "$mod_load_udp" ] && [ -z "$input_udp" ]; then
            echo "检测失败: UDP模块已加载，但未配置监听端口。"
            fail=1
        elif [ -n "$mod_load_udp" ]; then
            echo "检测成功: 已配置UDP监听。"
        fi
    fi

    return $fail
}

# 调用检查函数
if check_remote_logging_config; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


#!/bin/bash

# 默认配置文件路径
RSYSLOG_CONFIG_DIR="/etc/rsyslog.d"
RSYSLOG_CONFIG="/etc/rsyslog.conf"

# 显示帮助信息
usage() {
    echo "用法: $0 [-d 配置目录] [-c 主配置文件]"
    echo "  -d  指定rsyslog配置目录（默认为 /etc/rsyslog.d）"
    echo "  -c  指定主rsyslog配置文件（默认为 /etc/rsyslog.conf）"
    echo "  -h  显示此帮助信息"
}

# 解析命令行参数
while getopts "d:c:h" opt; do
    case $opt in
        d) RSYSLOG_CONFIG_DIR=$OPTARG ;;
        c) RSYSLOG_CONFIG=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) echo "无效选项: -$OPTARG" >&2; exit 1 ;;
    esac
done

# 检查远程日志服务器配置
check_remote_logging() {
    local fail=0
    local config_files="$RSYSLOG_CONFIG $(find $RSYSLOG_CONFIG_DIR -type f -name '*.conf')"

    # 查找配置文件中的远程服务器配置
    local pattern='^\s*.+\s+(@@?|&)\[?[\w\.\-]+\]?(:\d+)?'
    if ! grep -qP "$pattern" $config_files; then
        echo "检测失败: 配置文件中未配置远程日志服务器。"
        fail=1
    else
        echo "检测成功: 配置文件中已配置远程日志服务器。"
    fi

    return $fail
}

# 调用检查函数
if check_remote_logging; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


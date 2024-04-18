#!/bin/bash

CONFIG_FILE="/etc/ssh/sshd_config"
RECOMMENDED_LEVEL="verbose"

usage() {
    echo "Usage: $0 [-c config_path] [-l log_level] [-?]"
    echo "Options:"
    echo "  -c, --config       Specify the SSH configuration file path. Default is /etc/ssh/sshd_config"
    echo "  -l, --level        Specify the recommended log level, default is 'verbose'"
    echo "  -?, --help         Display this help message"
    exit 0
}

check_log_level() {
    local config_file=$1
    local recommended_level=$2

    local current_level=$(grep -Ei '^\s*LogLevel\s+' "$config_file" | tail -n 1 | awk '{print $2}' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [[ "$current_level" == "$recommended_level" ]]; then
        echo "检测成功: 日志级别设置正确，当前配置为: $current_level"
        return 0
    else
        echo "检测失败: 日志级别不符合推荐设置。当前配置：$current_level，推荐配置：$recommended_level"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        -l|--level)
            RECOMMENDED_LEVEL="$2"
            shift 2 ;;
        -\?|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 执行日志级别检查并处理返回值
if check_log_level "$CONFIG_FILE" "$RECOMMENDED_LEVEL"; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


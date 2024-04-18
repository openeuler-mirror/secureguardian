#!/bin/bash

CONFIG_FILE="/etc/ssh/sshd_config"

usage() {
    echo "Usage: $0 [--config <path>] [-?]"
    echo "Options:"
    echo "  --config       Specify the SSH configuration file path. Default is /etc/ssh/sshd_config"
    echo "  -?, --help     Display this help message"
    exit 0
}

# 函数：检查是否配置了ListenAddress
check_listen_address_configured() {
    local config_file=$1

    # 检查是否有ListenAddress的配置
    if grep -Eiq '^\s*ListenAddress\s+' "$config_file"; then
        echo "检测成功: 已配置ListenAddress。"
        return 0
    else
        echo "检测失败: 未配置任何ListenAddress。"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        -\?|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 执行检查
check_listen_address_configured "$CONFIG_FILE"
exit $?

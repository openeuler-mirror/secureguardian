#!/bin/bash

# 默认配置文件路径
CONFIG_FILE="/etc/ssh/sshd_config"

# 显示使用说明
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --config <path>    Specify the SSH configuration file path."
    echo "  -h, --help         Show this help message."
    echo "  --value <value>    Specify the expected value for MaxStartups to check."
    exit 0
}

# 检查MaxStartups配置
check_max_startups() {
    local config_file=$1
    local expected_value=$2
    local config_value=$(grep -i "^\s*MaxStartups" "$config_file" | awk '{print $2}')

    if [[ -z "$config_value" ]]; then
        echo "检测失败: MaxStartups 未在 $config_file 中配置。"
        return 1
    elif [[ -n "$expected_value" && "$config_value" != "$expected_value" ]]; then
        echo "检测失败: MaxStartups 配置值不符合期望（当前配置: $config_value, 期望配置: $expected_value）。"
        return 1
    else
        echo "检测成功: MaxStartups 已正确配置为 $config_value。"
        return 0
    fi
}

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        -v|--value)
            EXPECTED_VALUE="$2"
            shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 执行检查函数
check_max_startups "$CONFIG_FILE" "$EXPECTED_VALUE"
exit $?

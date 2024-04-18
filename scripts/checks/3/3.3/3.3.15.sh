#!/bin/bash

# 默认设置
expected_tries=3

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-e <expected_tries>] [-h]"
    echo "  -e, --expected-tries     Set the expected max authentication tries (default: 3)"
    echo "  -h, --help               Display this help message"
}

# 解析命令行参数
parse_params() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -e|--expected-tries)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    expected_tries=$2
                    shift
                else
                    echo "Error: Expected max authentication tries must be a number"
                    show_usage
                    exit 1
                fi
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Error: Invalid argument '$1'"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# 检查MaxAuthTries配置
check_max_auth_tries() {
    local config_file="/etc/ssh/sshd_config"
    local current_tries

    current_tries=$(grep -i "^MaxAuthTries" "$config_file" | awk '{print $2}')

    if [[ -z "$current_tries" ]]; then
        echo "检测失败:警告: MaxAuthTries 未配置，当前系统默认值为6。"
        return 1
    elif [[ "$current_tries" -le "$expected_tries" ]]; then
        echo "检查通过: MaxAuthTries 配置为 $current_tries，符合建议值。"
        return 0
    else
        echo "检测失败: MaxAuthTries 配置为 $current_tries，高于建议的最大尝试次数 $expected_tries。"
        return 1
    fi
}

# 主执行流程
main() {
    parse_params "$@"
    check_max_auth_tries
}

main "$@"


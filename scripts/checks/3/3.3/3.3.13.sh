#!/bin/bash

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-e <expected_max_sessions>] [-h]"
    echo "  -e, --expected-sessions  Set the expected max sessions (optional)"
    echo "  -h, --help               Display this help message"
}

# 解析命令行参数
parse_params() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -e|--expected-sessions)
                expected_max_sessions="$2"
                shift 2
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
    done
}

# 检查MaxSessions配置
check_max_sessions() {
    local config_file="/etc/ssh/sshd_config"
    local configured_sessions

    # 读取配置文件中的MaxSessions设置
    configured_sessions=$(grep -i "^MaxSessions" "$config_file" | awk '{print $2}')

    if [[ -z "$configured_sessions" ]]; then
        echo "检测失败: 'MaxSessions' 未在 $config_file 中配置。"
        return 1
    elif [[ -n "$expected_max_sessions" && "$configured_sessions" != "$expected_max_sessions" ]]; then
        echo "检测失败: 配置的MaxSessions为 $configured_sessions, 期望配置为 $expected_max_sessions."
        return 1
    else
        echo "检测通过: MaxSessions 配置存在，当前值为 $configured_sessions."
        return 0
    fi
}

# 主执行流程
main() {
    parse_params "$@"
    check_max_sessions
}

main "$@"


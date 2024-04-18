#!/bin/bash

# 默认配置文件路径
CONFIG_FILE="/etc/ssh/sshd_config"

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-c <config_file>] [-h]"
    echo "  -c, --config    Specify the SSH configuration file (default: /etc/ssh/sshd_config)"
    echo "  -h, --help      Display this help message"
}

# 解析命令行参数
parse_params() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -c|--config)
                if [[ -n "$2" ]]; then
                    CONFIG_FILE="$2"
                    shift
                else
                    echo "Error: Argument for $1 is missing"
                    show_usage
                    exit 1
                fi
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Error: Invalid argument $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# 检查 PermitUserEnvironment 配置
check_permit_user_environment() {
    local setting
    setting=$(grep -i "^\s*PermitUserEnvironment" "$CONFIG_FILE" | awk '{print $2}')

    if [[ "$setting" == "no" ]]; then
        echo "检查通过: PermitUserEnvironment 已正确设置为 'no'."
        return 0
    else
        echo "检测失败: PermitUserEnvironment 未设置为 'no'. 当前配置：$setting"
        return 1
    fi
}

# 主执行函数
main() {
    parse_params "$@"
    check_permit_user_environment
    local status=$?
    exit $status
}

main "$@"


#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Check Script for 3.3.17
#
# #######################################################################################

# 默认配置文件路径
CONFIG_FILE="/etc/ssh/sshd_config"
EXPECTED_TIME=60  # 默认推荐时间为60秒

# 显示帮助信息
show_usage() {
    echo "Usage: $0 [-c <config_file>] [-t <expected_time>] [-h]"
    echo "  -c, --config    Specify the SSH configuration file (default: /etc/ssh/sshd_config)"
    echo "  -t, --time      Expected max login grace time in seconds (default: 60)"
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
            -t|--time)
                if [[ -n "$2" ]]; then
                    EXPECTED_TIME="$2"
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

# 将时间字符串转换为秒
convert_to_seconds() {
    local time_string="$1"
    local total_seconds=0
    local multiplier=1

    # 检测是否包含时间单位
    case "${time_string: -1}" in
        s)
            multiplier=1  # 秒
            time_string="${time_string%?}"
            ;;
        m)
            multiplier=60  # 分钟
            time_string="${time_string%?}"
            ;;
        h)
            multiplier=3600  # 小时
            time_string="${time_string%?}"
            ;;
    esac

    # 计算总秒数
    if [[ "$time_string" =~ ^[0-9]+$ ]]; then
        total_seconds=$((time_string * multiplier))
    else
        echo "Error: Invalid time format '$time_string'"
        exit 1
    fi

    echo $total_seconds
}

# 检查 LoginGraceTime 配置
check_login_grace_time() {
    local setting
    setting=$(grep -i "^LoginGraceTime" "$CONFIG_FILE" | awk '{print $2}')
    local setting_in_seconds

    if [[ -n "$setting" ]]; then
        setting_in_seconds=$(convert_to_seconds "$setting")
        if [[ "$setting_in_seconds" -le "$EXPECTED_TIME" ]]; then
            echo "检查通过: LoginGraceTime 设置正确且小于等于 $EXPECTED_TIME 秒。"
            return 0
        else
            echo "检测失败: LoginGraceTime 配置值应小于等于 $EXPECTED_TIME 秒。当前配置：$setting"
            return 1
        fi
    else
        echo "检测失败: LoginGraceTime 未配置。"
        return 1
    fi
}

# 主执行函数
main() {
    parse_params "$@"
    check_login_grace_time
    local status=$?
    exit $status
}

main "$@"


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
# Description: Security Baseline Check Script for 3.3.2
#
# #######################################################################################

# 默认配置路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"

# 参数解析和帮助信息
usage() {
    echo "用法: $0 [-c config_path]"
    echo "选项:"
    echo "  -c, --config    指定SSH配置文件的路径 (默认为/etc/ssh/sshd_config)"
    echo "  -?, --help      显示帮助信息"
}

# 分析配置文件的认证方式
check_ssh_authentication() {
    local config_file=$1

    if [[ ! -f "$config_file" ]]; then
        echo "检测失败: 配置文件不存在: $config_file"
        return 1
    fi

    declare -A required_configs=(
        [PasswordAuthentication]="yes"
        [PubkeyAuthentication]="yes"
        [ChallengeResponseAuthentication]="yes"
        [IgnoreRhosts]="yes"
        [HostbasedAuthentication]="no"
    )

    local key value missing_configs=0
    local auth_enabled=0

    for key in "${!required_configs[@]}"; do
        value=$(grep -E "^\s*${key}\s+" "$config_file" | awk '{print $2}' | tr -d ' ')
        if [[ "$key" =~ ^(PasswordAuthentication|PubkeyAuthentication|ChallengeResponseAuthentication)$ ]]; then
            if [[ "$value" == "yes" ]]; then
                auth_enabled=1
                continue  # 跳过其他检查，因为已经找到至少一个启用的认证方式
            fi
        else
            if [[ "$value" != "${required_configs[$key]}" ]]; then
                echo "检测不成功: $key 配置错误，当前值为'$value'，期望值为'${required_configs[$key]}'"
                missing_configs=$((missing_configs+1))
            fi
        fi
    done

    if [[ $auth_enabled -eq 0 ]]; then
        echo "检测失败: 至少需要启用一种认证方式（密码、公钥或挑战响应认证）。"
        missing_configs=$((missing_configs+1))
    fi

    if ((missing_configs > 0)); then
        return 1
    else
        echo "检测成功: 所有必要的认证方式至少有一个已被启用，且其他配置正确。"
        return 0
    fi
}

# 处理输入参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config) config_file="$2"; shift ;;
        -\?|--help) usage; exit 0 ;;
        * ) echo "未知选项: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

config_file="${config_file:-$DEFAULT_CONFIG}"

# 执行配置检查
if check_ssh_authentication "$config_file"; then
    exit 0
else
    exit 1
fi


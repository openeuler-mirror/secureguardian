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
# Description: Security Baseline Check Script for 3.3.7
#
# #######################################################################################

# 默认SSH配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
# 推荐的安全密码算法列表
RECOMMENDED_CIPHERS="aes128-ctr,aes192-ctr,aes256-ctr,chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes256-gcm@openssh.com"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [-a additional_ciphers] [-?]"
    echo "选项:"
    echo "  -c, --config       指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  -a, --additional-ciphers  添加用户定义的允许密码算法，用逗号分隔"
    echo "  -?, --help         显示帮助信息"
    exit 0
}

# 检查SSH服务的密码算法配置
check_ciphers_configuration() {
    local config_file=$1
    local additional_ciphers=$2
    local valid_ciphers=${RECOMMENDED_CIPHERS}

    if [[ -n "$additional_ciphers" ]]; then
        valid_ciphers+=",${additional_ciphers}"
    fi

    # 读取配置文件中的Ciphers设置
    local ciphers_setting=$(grep -i "^Ciphers" "$config_file" | cut -d ' ' -f2- | tr -d ' ' | tr ',' '\n' | sort | uniq | tr '\n' ',')

    if [[ -z "$ciphers_setting" ]]; then
        echo "检测失败: Ciphers 配置项未在 $config_file 中设置"
        return 1
    fi

    # 检查配置中的算法是否全部在允许列表中
    local ciphers_array=(${ciphers_setting//,/ })
    local invalid_found=0

    for cipher in "${ciphers_array[@]}"; do
        if [[ ! ",${valid_ciphers}," =~ ",${cipher}," ]]; then
            echo "检测失败: Ciphers 配置包含非允许的算法 '${cipher}'"
            invalid_found=1
        fi
    done

    if [[ $invalid_found -eq 1 ]]; then
        return 1
    else
        echo "检测成功:Ciphers 配置正确。当前设置: ${ciphers_setting%,}"
        return 0
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
            shift 2 ;;
        -a|--additional-ciphers)
            additional_ciphers="$2"
            shift 2 ;;
        -\?|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 设置默认配置文件路径
config_file="${config_file:-$DEFAULT_CONFIG}"

# 执行密码算法检查
if check_ciphers_configuration "$config_file" "$additional_ciphers"; then
    exit 0
else
    exit 1
fi


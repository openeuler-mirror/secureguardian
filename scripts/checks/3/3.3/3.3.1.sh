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
# Description: Security Baseline Check Script for 3.3.1
#
# #######################################################################################

# 默认配置文件路径
DEFAULT_SSHD_CONFIG="/etc/ssh/sshd_config"
sshd_config="${1:-$DEFAULT_SSHD_CONFIG}"

check_ssh_protocol() {
    local config_file=$1
    if [[ ! -f "$config_file" ]]; then
        echo "检测失败: 指定的配置文件不存在: $config_file"
        return 1
    fi

    # 使用扩展正则表达式以处理可能的额外空格
    local protocol_setting=$(grep -E "^\s*Protocol\s+" "$config_file" | awk '{print $2}' | tr -d ' ')
    if [[ "$protocol_setting" != "2" ]]; then
        echo "检测失败: SSH协议版本不正确, 当前设置为: $protocol_setting, 要求为2"
        return 1
    fi

    echo "SSH协议版本配置正确: $protocol_setting"
    return 0
}

# 解析参数
while getopts ":c:?:" opt; do
    case $opt in
        c)
            sshd_config="$OPTARG"
            ;;
        \?)
            echo "用法: $0 [-c sshd_config_path]"
            exit 1
            ;;
    esac
done

# 调用函数
if check_ssh_protocol "$sshd_config"; then
    exit 0
else
    exit 1
fi


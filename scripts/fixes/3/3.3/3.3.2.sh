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
# Description: Security Baseline fix Script for 3.3.2
#
# #######################################################################################
# 确保 SSH 服务认证方式配置正确
#
# 功能说明：
# - 确保 SSH 配置文件中认证方式的设置符合要求。
# - 修复必要配置项，如开启密码认证、公钥认证、挑战响应认证。
# - 禁止基于主机的认证，并启用 IgnoreRhosts。
# - 提供自测功能，通过模拟场景验证修复逻辑。

# 默认配置路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
config_file="$DEFAULT_CONFIG"

# 显示使用说明
usage() {
    echo "用法: $0 [-c config_path] [--self-test]"
    echo "选项:"
    echo "  -c, --config    指定 SSH 配置文件的路径 (默认为 /etc/ssh/sshd_config)"
    echo "  --self-test     自测模式，模拟问题场景并验证修复逻辑"
    echo "  -?, --help      显示帮助信息"
}

# 修复 SSH 认证方式配置
fix_ssh_authentication() {
    local config_file=$1

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    # 确保必要的配置项
    echo "正在修复 SSH 配置文件中的认证方式设置..."
    declare -A required_configs=(
        [PasswordAuthentication]="yes"
        [PubkeyAuthentication]="yes"
        [ChallengeResponseAuthentication]="yes"
        [IgnoreRhosts]="yes"
        [HostbasedAuthentication]="no"
    )

    for key in "${!required_configs[@]}"; do
        if grep -qE "^\s*$key\s+" "$config_file"; then
            sed -i "s|^\s*$key\s\+.*|$key ${required_configs[$key]}|" "$config_file"
            echo "已修复: $key = ${required_configs[$key]}"
        else
            echo "$key ${required_configs[$key]}" >> "$config_file"
            echo "已添加: $key = ${required_configs[$key]}"
        fi
    done

    # 重启 SSH 服务
    echo "正在重启 sshd 服务以应用配置更改..."
    systemctl restart sshd

    if [[ $? -eq 0 ]]; then
        echo "sshd 服务已成功重启，修复完成。"
    else
        echo "错误: sshd 服务重启失败，请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."

    local test_config="/tmp/sshd_config.test"
    cp "$config_file" "$test_config"

    # 模拟错误配置
    echo "PasswordAuthentication no" > "$test_config"
    echo "PubkeyAuthentication no" >> "$test_config"
    echo "ChallengeResponseAuthentication no" >> "$test_config"
    echo "IgnoreRhosts no" >> "$test_config"
    echo "HostbasedAuthentication yes" >> "$test_config"
    echo "已模拟错误配置文件: $test_config"

    # 调用修复函数
    fix_ssh_authentication "$test_config"

    # 验证修复结果
    local errors=0
    while read -r key value; do
        actual_value=$(grep -E "^\s*$key\s+" "$test_config" | awk '{print $2}')
        if [[ "$actual_value" != "$value" ]]; then
            echo "自测失败: $key 未正确修复，当前值为 $actual_value，期望值为 $value"
            errors=$((errors+1))
        fi
    done < <(printf "%s\n" "PasswordAuthentication yes" "PubkeyAuthentication yes" \
                   "ChallengeResponseAuthentication yes" "IgnoreRhosts yes" \
                   "HostbasedAuthentication no")

    rm -f "$test_config"

    if [[ $errors -eq 0 ]]; then
        echo "自测成功: 所有修复逻辑验证通过。"
        return 0
    else
        echo "自测失败: 存在未正确修复的配置项。"
        return 1
    fi
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
            shift; shift
            ;;
        --self-test)
            self_test
            exit $?
            ;;
        -\?|--help)
            usage
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 执行修复逻辑
fix_ssh_authentication "$config_file"

echo "SSH 服务认证方式已确保配置正确。"
exit 0


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
# 确保 SSH 服务协议版本配置正确
#
# 功能说明：
# - 确保 SSH 服务协议设置为 Protocol 2。
# - 支持通过参数指定 sshd 配置文件路径。
# - 提供自测功能，通过模拟场景验证修复逻辑。

# 默认配置文件路径
DEFAULT_SSHD_CONFIG="/etc/ssh/sshd_config"
sshd_config="${DEFAULT_SSHD_CONFIG}"

# 显示使用说明
show_usage() {
    echo "用法: $0 [-c sshd_config_path] [--self-test]"
    echo "示例: $0 -c /etc/ssh/sshd_config"
    echo "      $0 --self-test"
    echo "默认配置文件路径: /etc/ssh/sshd_config"
}

# 修复 SSH 协议版本配置
fix_ssh_protocol() {
    local config_file=$1

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    # 确保 Protocol 2 配置正确
    echo "正在确保 SSH 服务协议版本为 Protocol 2..."
    if grep -qE "^\s*Protocol\s+" "$config_file"; then
        sed -i 's/^\s*Protocol\s\+.*/Protocol 2/' "$config_file"
        echo "已更新配置文件中的 Protocol 配置为 Protocol 2。"
    else
        echo "Protocol 2" >> "$config_file"
        echo "已在配置文件末尾添加 Protocol 2 配置。"
    fi

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
    cp "$sshd_config" "$test_config"

    # 模拟不正确的 Protocol 配置
    echo "Protocol 1" > "$test_config"
    echo "已模拟错误的 Protocol 配置: $test_config"

    # 调用修复函数
    fix_ssh_protocol "$test_config"

    # 检查修复结果
    if grep -qE "^\s*Protocol\s+2" "$test_config"; then
        echo "自测成功: 修复逻辑已正确设置 Protocol 为 2。"
        rm -f "$test_config"
        return 0
    else
        echo "自测失败: 修复逻辑未正确设置 Protocol 为 2。"
        rm -f "$test_config"
        return 1
    fi
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            sshd_config="$2"
            shift; shift
            ;;
        --self-test)
            self_test
            exit $?
            ;;
        /?|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 执行修复逻辑
fix_ssh_protocol "$sshd_config"

echo "SSH 服务协议版本配置已确保为 Protocol 2。"
exit 0


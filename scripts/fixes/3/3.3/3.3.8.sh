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
# Description: Security Baseline fix Script for 3.3.8
#
# #######################################################################################
# 禁止SSH服务配置加密算法覆盖策略
#
# 功能说明：
# - 确保 SSH 服务配置文件中未设置加密算法覆盖策略。
# - 移除或注释掉 CRYPTO_POLICY 配置项。
# - 提供自测功能，通过模拟场景验证修复逻辑。

# 默认配置文件路径
CONFIG_FILE="/etc/ssh/sshd_config"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [--self-test] [-?]"
    echo "选项:"
    echo "  -c, --config    指定SSH sysconfig 文件的路径，默认为/etc/sysconfig/sshd"
    echo "  --self-test     自测模式，模拟问题场景并验证修复逻辑"
    echo "  -?, --help      显示帮助信息"
    exit 0
}

# 修复加密算法覆盖策略
fix_crypto_policy() {
    local config_file=$1

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    # 修复 CRYPTO_POLICY 设置
    echo "正在修复 SSH 配置文件中的 CRYPTO_POLICY 设置..."
    if grep -q "^\s*CRYPTO_POLICY=" "$config_file"; then
        # 注释掉现有的 CRYPTO_POLICY 行
        sed -i 's/^\s*\(CRYPTO_POLICY=.*\)$/# \1/' "$config_file"
        echo "已注释掉配置文件中的 CRYPTO_POLICY 设置。"
    else
        echo "配置文件中未找到 CRYPTO_POLICY 设置，无需修复。"
    fi

    # 重新加载 SSH 服务
    echo "正在重新加载 sshd 服务以应用配置更改..."
    systemctl reload sshd

    if [[ $? -eq 0 ]]; then
        echo "sshd 服务已成功重新加载，修复完成。"
    else
        echo "错误: sshd 服务重新加载失败，请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."

    local test_config="/tmp/sshd_config.test"
    cp "$CONFIG_FILE" "$test_config"

    # 模拟错误配置
    echo "CRYPTO_POLICY='-oCiphers=aes256-ctr -oMACS=hmac-sha2-512'" > "$test_config"
    echo "已模拟错误配置文件: $test_config"

    # 调用修复函数
    fix_crypto_policy "$test_config"

    # 验证修复结果
    if grep -q "^\s*#\s*CRYPTO_POLICY=" "$test_config"; then
        echo "自测成功: 修复逻辑已正确注释 CRYPTO_POLICY 设置。"
        rm -f "$test_config"
        return 0
    else
        echo "自测失败: 修复逻辑未正确注释 CRYPTO_POLICY 设置。"
        rm -f "$test_config"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        --self-test)
            self_test
            exit $? ;;
        -\?|--help)
            usage ;;
        *)
            echo "无效选项: $1"
            usage ;;
    esac
done

# 执行修复逻辑
fix_crypto_policy "$CONFIG_FILE"

echo "SSH 加密算法覆盖策略已禁用。"
exit 0


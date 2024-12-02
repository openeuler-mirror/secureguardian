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
# Description: Security Baseline Fix Script for 2.6.2
#
# #######################################################################################
#
# 修复全局加解密策略，确保不低于DEFAULT
#
# 功能说明：
# - 检查并修复全局加解密策略配置。
# - 确保 /etc/crypto-policies/config 存在。
# - 提供自测功能，验证修复逻辑。
#
# #######################################################################################

CONFIG_FILE="/etc/crypto-policies/config"

# 确保配置文件存在
ensure_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "配置文件 $CONFIG_FILE 不存在，正在创建..."
        echo "DEFAULT" >"$CONFIG_FILE"
        echo "配置文件已创建并设置为 DEFAULT 策略。"
    else
        echo "配置文件 $CONFIG_FILE 存在。"
    fi
}

# 检查并修复加解密策略
fix_crypto_policy() {
    local allowed_policies=("DEFAULT" "NEXT" "FUTURE" "FIPS")
    local current_policy

    # 读取当前策略，忽略注释和空行
    current_policy=$(grep -vE '^\s*#|^\s*$' "$CONFIG_FILE")

    # 如果当前策略为空或不在允许的策略列表中，设置为 DEFAULT
    if [[ ! " ${allowed_policies[*]} " =~ " $current_policy " ]]; then
        echo "当前策略为 \"$current_policy\"，不符合要求。正在修复为 DEFAULT 策略..."
        echo "DEFAULT" >"$CONFIG_FILE"
        echo "修复完成: 策略已设置为 DEFAULT。"
    else
        echo "当前策略为 \"$current_policy\"，符合要求，无需修复。"
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟修复加解密策略..."
    local test_config="/tmp/crypto-policies.config.test"

    # 模拟创建测试配置文件
    echo "LEGACY" >"$test_config"
    echo "模拟配置文件已创建，路径: $test_config"

    # 调用修复函数
    CONFIG_FILE="$test_config"
    fix_crypto_policy

    # 检查修复结果
    local fixed_policy
    fixed_policy=$(grep -vE '^\s*#|^\s*$' "$test_config")
    if [[ "$fixed_policy" == "DEFAULT" ]]; then
        echo "自测成功: 策略已成功修复为 DEFAULT。"
        rm -f "$test_config"
    else
        echo "自测失败: 修复后的策略为 \"$fixed_policy\"，不符合预期。"
        exit 1
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            echo "使用方法: $0 [--self-test]"
            exit 1
            ;;
    esac
done

# 主修复逻辑
ensure_config_file
fix_crypto_policy

echo "全局加解密策略已成功修复并符合要求。"
exit 0


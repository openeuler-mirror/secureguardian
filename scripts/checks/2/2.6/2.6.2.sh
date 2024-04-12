#!/bin/bash

# 函数：检查加解密策略配置
check_crypto_policy() {
    local config_file="/etc/crypto-policies/config"

    # 检查配置文件是否存在
    if [ ! -f "$config_file" ]; then
        echo "检测失败: 加解密策略配置文件不存在"
        return 1
    fi

    # 读取配置文件中的策略，忽略注释和空行
    local policy=$(grep -vE '^\s*#|^\s*$' "$config_file")

    # 列出所有允许的策略，LEGACY 不包含在内
    local allowed_policies="DEFAULT NEXT FUTURE FIPS"

    # 检查配置文件中的策略是否符合要求
    if [[ " $allowed_policies " =~ " $policy " ]]; then
        echo "检查成功: 当前加解密策略为 $policy，符合要求。"
        return 0
    else
        echo "检测失败: 当前加解密策略为 $policy，不符合要求。"
        return 1
    fi
}

# 主逻辑
if check_crypto_policy; then
    exit 0  # 检查成功，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


#!/bin/bash

# 默认配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
# 推荐的安全算法列表，使用数组形式
RECOMMENDED_KEY_TYPES=("ssh-ed25519" "ssh-ed25519-cert-v01@openssh.com" "rsa-sha2-256" "rsa-sha2-512")

# 使用帮助函数显示用法信息
usage() {
    echo "用法: $0 [-c config_path] [-a additional_key_types] [-?]"
    echo "选项:"
    echo "  -c, --config                指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  -a, --additional-key-types  添加用户定义的允许密钥算法，用逗号分隔"
    echo "  -?, --help                  显示帮助信息"
    exit 1
}

# 检查SSH用户认证密钥算法配置
check_pubkey_accepted_key_types() {
    local config_file=$1
    local additional_key_types=$2
    local valid_key_types=("${RECOMMENDED_KEY_TYPES[@]}")

    # 添加用户自定义的允许密钥算法
    if [[ -n "$additional_key_types" ]]; then
        IFS=',' read -ra ADDR <<< "$additional_key_types"
        for i in "${ADDR[@]}"; do
            valid_key_types+=("$i")
        done
    fi

    # 读取配置文件中的PubkeyAcceptedKeyTypes设置
    local kex_settings=$(grep -E "^\s*PubkeyAcceptedKeyTypes\s+" "$config_file" | cut -d ' ' -f2- | tr -d ' ')

    if [[ -z "$kex_settings" ]]; then
        echo "检测失败: PubkeyAcceptedKeyTypes 配置项未在 $config_file 中设置"
        return 1
    fi

    local kex_array=($(echo $kex_settings | tr ',' '\n'))
    local invalid_found=0

    # 检查每个配置的算法是否在允许列表中
    for alg in "${kex_array[@]}"; do
        if [[ ! " ${valid_key_types[*]} " =~ " $alg " ]]; then
            echo "检测失败: PubkeyAcceptedKeyTypes 配置包含非允许的算法 '$alg'"
            invalid_found=1
        fi
    done

    if [[ $invalid_found -eq 1 ]]; then
        return 1
    else
        echo "检测成功:PubkeyAcceptedKeyTypes 配置正确"
        return 0
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"; shift;;
        -a|--additional-key-types)
            additional_key_types="$2"; shift;;
        -\?|--help)
            usage;;
        *)
            echo "未知选项: $1"
            usage;;
    esac
    shift
done

config_file="${config_file:-$DEFAULT_CONFIG}"

# 执行用户认证密钥算法检查
if check_pubkey_accepted_key_types "$config_file" "$additional_key_types"; then
    exit 0
else
    exit 1
fi


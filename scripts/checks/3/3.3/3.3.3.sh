#!/bin/bash

# 默认配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
# 推荐的安全算法列表
RECOMMENDED_KEX=("curve25519-sha256" "curve25519-sha256@libssh.org" "diffie-hellman-group-exchange-sha256")

# 使用帮助函数显示用法信息
usage() {
    echo "用法: $0 [-c config_path] [-a additional_algorithms] [-?]"
    echo "选项:"
    echo "  -c, --config                指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  -a, --additional-algorithms 添加用户定义的允许算法，用逗号分隔"
    echo "  -?, --help                  显示帮助信息"
    exit 1
}

# 检查SSH密钥交换算法配置
check_kex_algorithms() {
    local config_file=$1
    local additional_algorithms=$2
    local allowed_kex=("${RECOMMENDED_KEX[@]}")

    if [[ -n "$additional_algorithms" ]]; then
        IFS=',' read -ra ADDR <<< "$additional_algorithms"
        for i in "${ADDR[@]}"; do
            allowed_kex+=("$i")
        done
    fi

    # 读取配置文件中的KexAlgorithms设置
    local kex_setting=$(grep -E "^\s*KexAlgorithms\s+" "$config_file" | cut -d ' ' -f2- | tr -d ' ' | tr ',' '\n' | sort | uniq)

    # 验证配置中的算法是否全部在允许列表中
    local invalid_found=0
    for alg in $kex_setting; do
        if [[ ! " ${allowed_kex[*]} " =~ " $alg " ]]; then
            echo "检测失败: 配置中包含非允许的算法 '$alg'"
            invalid_found=1
        fi
    done

    if (( invalid_found == 1 )); then
        return 1
    fi

    echo "检查成功:KexAlgorithms 配置正确"
    return 0
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"; shift;;
        -a|--additional-algorithms)
            additional_algorithms="$2"; shift;;
        -\?|--help)
            usage;;
        *)
            echo "未知选项: $1"
            usage;;
    esac
    shift
done

config_file="${config_file:-$DEFAULT_CONFIG}"

# 执行密钥交换算法检查
if check_kex_algorithms "$config_file" "$additional_algorithms"; then
    exit 0
else
    exit 1
fi


#!/bin/bash

# 默认SSH配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
# 推荐的安全MAC算法列表
RECOMMENDED_MACS="hmac-sha2-512,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-256-etm@openssh.com"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [-a additional_macs] [-?]"
    echo "选项:"
    echo "  -c, --config       指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  -a, --additional-macs  添加用户定义的允许MAC算法，用逗号分隔"
    echo "  -?, --help         显示帮助信息"
    exit 0
}

# 检查SSH服务的MACs算法配置
check_macs_configuration() {
    local config_file=$1
    local additional_macs=$2
    local valid_macs=${RECOMMENDED_MACS}

    if [[ -n "$additional_macs" ]]; then
        valid_macs+=",${additional_macs}"
    fi

    # 读取配置文件中的MACs设置
    local macs_setting=$(grep -i "^MACs" "$config_file" | cut -d ' ' -f2- | tr -d ' ' | tr ',' '\n' | sort | uniq | tr '\n' ',')

    if [[ -z "$macs_setting" ]]; then
        echo "检测失败: MACs 配置项未在 $config_file 中设置"
        return 1
    fi

    # 检查配置中的算法是否全部在允许列表中
    local macs_array=(${macs_setting//,/ })
    local invalid_found=0

    for mac in "${macs_array[@]}"; do
        if [[ ! ",${valid_macs}," =~ ",${mac}," ]]; then
            echo "检测失败: MACs 配置包含非允许的算法 '${mac}'"
            invalid_found=1
        fi
    done

    if [[ $invalid_found -eq 1 ]]; then
        return 1
    else
        echo "检测成功:MACs 配置正确。当前设置: ${macs_setting%,}"
        return 0
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
            shift 2 ;;
        -a|--additional-macs)
            additional_macs="$2"
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

# 执行MACs算法检查
if check_macs_configuration "$config_file" "$additional_macs"; then
    exit 0
else
    exit 1
fi


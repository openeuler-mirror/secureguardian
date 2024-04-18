#!/bin/bash

# 默认SSH配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [-?]"
    echo "选项:"
    echo "  -c, --config    指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  -?, --help      显示帮助信息"
    exit 0
}

# 检查PAM认证是否启用
check_pam_authentication() {
    local config_file=$1

    # 读取配置文件中的UsePAM设置
    local pam_setting=$(grep -i "^UsePAM" "$config_file")

    # 清理得到的设置，移除空格和注释
    pam_setting=$(echo "$pam_setting" | sed 's/#.*//' | awk '{print $2}')

    if [[ "$pam_setting" != "yes" ]]; then
        echo "检测失败: PAM认证未启用。当前设置为'${pam_setting:-未设置}'，应为'yes'。"
        return 1
    fi

    echo "检查成功:PAM认证配置正确，已启用。"
    return 0
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
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

# 执行PAM认证检查
if check_pam_authentication "$config_file"; then
    exit 0
else
    exit 1
fi


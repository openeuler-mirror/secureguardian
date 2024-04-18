#!/bin/bash

# 功能说明:
# 此脚本用于确保SSH的TCP转发功能被禁用。
# 它会检查运行时配置和sshd_config文件中的配置。

CONFIG_FILE="/etc/ssh/sshd_config"

# 检查 AllowTcpForwarding 是否正确配置为no
check_tcp_forwarding() {
    # 使用sshd命令检查运行时的配置
    local runtime_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | awk '/^allowtcpforwarding/ {print $2}')
    
    # 从配置文件中获取最后一条有效的AllowTcpForwarding设置
    local file_setting=$(grep -Ei '^\s*AllowTcpForwarding' "$CONFIG_FILE" | tail -n 1 | awk '{print $2}')

    # 检查两个地方的配置是否都为no
    if [[ "$runtime_setting" == "no" && "$file_setting" != "yes" ]]; then
        echo "检查通过: TCP转发已禁用。"
        return 0
    else
        echo "检测失败: TCP转发未正确禁用。当前运行时设置为：$runtime_setting，文件设置为：$file_setting。"
        return 1
    fi
}

# 调用检查函数并处理返回值
if check_tcp_forwarding; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


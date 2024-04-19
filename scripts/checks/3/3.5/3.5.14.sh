#!/bin/bash

# 功能说明：
# 此脚本用于检查系统是否启用了TCP-SYN cookie保护，以防御SYN Flood攻击。

check_tcp_syncookies() {
    # 检查TCP-SYN cookie的当前设置
    local tcp_syncookies=$(sysctl -n net.ipv4.tcp_syncookies)

    # 判断TCP-SYN cookie是否启用（应设置为1）
    if [[ "$tcp_syncookies" -eq 1 ]]; then
        echo "检测成功: TCP-SYN cookie保护已启用。"
        return 0
    else
        echo "检测失败: TCP-SYN cookie保护未启用。当前值：$tcp_syncookies"
        return 1
    fi
}

# 调用函数并处理返回值
if check_tcp_syncookies; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


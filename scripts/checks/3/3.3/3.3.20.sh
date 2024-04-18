#!/bin/bash

# 功能：检查 SSH 配置文件是否包含弃用的选项

CONFIG_FILE="/etc/ssh/sshd_config"

# 检查 SSH 配置文件
check_ssh_config() {
    # 使用 sshd 命令测试配置文件
    local errors=$(sshd -t -f "$CONFIG_FILE" 2>&1 || true)

    # 检查输出中是否含有 "Deprecated" 或 "error" 字样
    if echo "$errors" | grep -E "Deprecated|error"; then
        echo "检测失败: 配置文件包含弃用的选项或配置错误"
        echo "$errors"
        return 1
    else
        echo "检查通过: 未发现弃用的配置选项"
        return 0
    fi
}

# 调用检查函数并处理结果
if check_ssh_config; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


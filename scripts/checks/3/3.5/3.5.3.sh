#!/bin/bash

# 功能说明：检查 kptr_restrict 参数是否设置为1

function check_kptr_restrict() {
    local current_value=$(sysctl -n kernel.kptr_restrict)
    if [ "$current_value" -eq 1 ]; then
        echo "检查通过: kptr_restrict 设置正确。"
        return 0
    else
        echo "检测失败: kptr_restrict 当前值为 $current_value，应设置为 1。"
        return 1
    fi
}

# 调用检查函数并处理返回值
if check_kptr_restrict; then
    exit 0
else
    exit 1
fi


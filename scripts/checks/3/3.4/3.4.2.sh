#!/bin/bash

# 功能说明：此脚本用于检测 cron 守护进程是否正常启用。
# 脚本会检查 crond 服务的启用状态以及运行状态，确保系统定时任务能够正常执行。

check_cron_service() {
    # 检查 crond 服务是否启用
    local enabled=$(systemctl is-enabled crond 2>/dev/null)
    if [ "$enabled" != "enabled" ]; then
        echo "检测失败: crond 服务未启用。"
        return 1
    fi

    # 检查 crond 服务是否正在运行
    local active=$(systemctl is-active crond 2>/dev/null)
    if [ "$active" != "active" ]; then
        echo "检测失败: crond 服务未运行。"
        return 1
    fi

    # 如果 crond 服务启用并且正在运行，打印成功消息
    echo "检查成功:crond 服务已正确启用并运行。"
    return 0
}

# 调用检测函数
if check_cron_service; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


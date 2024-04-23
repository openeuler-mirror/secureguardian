#!/bin/bash

# 检查cron日志是否已配置
check_cron_logs() {
    # 搜索rsyslog配置中关于cron日志的配置
    local cron_log_config=$(grep cron /etc/rsyslog.conf | grep -v "^#")
    
    # 检测是否包含cron.*配置指向/var/log/cron
    if echo "$cron_log_config" | grep -q "cron.*[[:space:]]*/var/log/cron"; then
        echo "检查通过: cron服务日志已正确配置。"
        return 0
    else
        echo "检测失败: cron服务日志未正确配置。"
        return 1
    fi
}

# 调用检测函数并处理返回值
if check_cron_logs; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


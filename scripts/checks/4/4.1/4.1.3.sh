#!/bin/bash

# 功能说明:
# 此脚本用于检查 /var/log/lastlog 文件的审计配置。
# 它将验证是否已经为该文件配置了监控登录事件的审计规则，不考虑关键字。

# 检查审计规则函数
function check_audit_rule_for_lastlog() {
    local lastlog_audit_rule=$(auditctl -l | grep -i "/var/log/lastlog")
    
    if [[ -z "$lastlog_audit_rule" ]]; then
        echo "检测失败: /var/log/lastlog 未设置审计规则。"
        return 1
    else
        echo "检测成功: /var/log/lastlog 已设置审计规则。"
        echo "当前规则: $lastlog_audit_rule"
        return 0
    fi
}

# 调用检查函数并处理返回值
if check_audit_rule_for_lastlog; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


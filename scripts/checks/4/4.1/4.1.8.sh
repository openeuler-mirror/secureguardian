#!/bin/bash

# 功能说明:
# 本脚本用于检查操作系统启动阶段是否启用了auditd。
# 它会检查内核启动参数中是否设置了'audit=1'。
# 如果内核参数中没有显式地设置'audit=1'，则使用auditctl -s命令进一步确认审计状态。

# 检查内核启动参数中的审计设置
check_audit_enabled_at_boot() {
    # 获取当前内核启动参数
    local cmdline=$(cat /proc/cmdline)

    # 检查是否显式禁用了审计
    if echo "$cmdline" | grep -q "audit=0"; then
        echo "检测失败: 审计在启动时被禁用。"
        return 1
    fi

    # 检查是否显式启用了审计
    if echo "$cmdline" | grep -q "audit=1"; then
        echo "检测成功: 审计在启动时已启用。"
        return 0
    else
        # 使用auditctl -s检查当前审计系统的状态
        local audit_status=$(auditctl -s | grep "enabled" | awk '{print $2}')
        if [ "$audit_status" -gt 0 ]; then
            echo "检测成功: 审计系统当前处于启用状态。"
            return 0
        else
            echo "检测失败: 审计系统当前未启用。"
            return 1
        fi
    fi
}

# 调用检查函数并处理返回值
if check_audit_enabled_at_boot; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi

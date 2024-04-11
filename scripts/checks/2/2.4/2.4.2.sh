#!/bin/bash

# 函数：检查SELinux是否处于强制模式
check_selinux_enforcing() {
    local current_mode=$(getenforce)
    local config_mode=$(grep "^SELINUX=" /etc/selinux/config | cut -d'=' -f2 | tr -d ' ')

    if [[ "$current_mode" != "Enforcing" || "$config_mode" != "enforcing" ]]; then
        echo "检测失败:SELinux未配置为强制模式。"
        return 1
    else
        echo "检测成功:SELinux已配置为强制模式。"
        return 0
    fi
}

# 调用函数并处理返回值
check_selinux_enforcing
exit $?


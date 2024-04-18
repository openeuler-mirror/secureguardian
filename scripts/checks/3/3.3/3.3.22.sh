#!/bin/bash

# 检查 SSH 认证黑白名单
function check_ssh_auth_lists() {
    local config_file="/etc/ssh/sshd_config"
    local found_issues=0

    # 检查 AllowUsers 配置
    if grep -Eq "^\s*AllowUsers" "$config_file"; then
        echo "找到 AllowUsers 配置:"
        grep "^\s*AllowUsers" "$config_file"
        found_issues=$((found_issues+1))
    else
        echo "未找到 AllowUsers 配置。"
    fi

    # 检查 AllowGroups 配置
    if grep -Eq "^\s*AllowGroups" "$config_file"; then
        echo "找到 AllowGroups 配置:"
        grep "^\s*AllowGroups" "$config_file"
        found_issues=$((found_issues+1))
    else
        echo "未找到 AllowGroups 配置。"
    fi

    # 检查 DenyUsers 配置
    if grep -Eq "^\s*DenyUsers" "$config_file"; then
        echo "找到 DenyUsers 配置:"
        grep "^\s*DenyUsers" "$config_file"
        found_issues=$((found_issues+1))
    else
        echo "未找到 DenyUsers 配置。"
    fi

    # 检查 DenyGroups 配置
    if grep -Eq "^\s*DenyGroups" "$config_file"; then
        echo "找到 DenyGroups 配置:"
        grep "^\s*DenyGroups" "$config_file"
        found_issues=$((found_issues+1))
    else
        echo "未找到 DenyGroups 配置。"
    fi

    # 根据检查结果返回成功或失败
    if [ $found_issues -gt 0 ]; then
        echo "检查通过，找到至少一个配置项。"
        return 0
    else
        echo "检查未通过，没有找到任何配置项。"
        return 1
    fi
}

# 调用检查函数并处理返回值
if check_ssh_auth_lists; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


#!/bin/bash

# 函数：检查SELinux策略是否正确配置
check_selinux_policy() {
    # 从命令行参数获取期望的策略类型，默认为 targeted
    local expectedPolicyType="${1:-targeted}"
    local configFile="/etc/selinux/config"
    local currentPolicyType

    # 检查SELinux配置文件是否存在
    if [ ! -f "$configFile" ]; then
        echo "SELinux配置文件不存在。"
        exit 1
    fi

    # 使用grep和正则表达式提取SELINUXTYPE的值，忽略空格，仅输出匹配的部分
    currentPolicyType=$(grep -oP "^\s*SELINUXTYPE\s*=\s*\K.*" "$configFile" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    # 检查是否成功找到策略类型配置
    if [ -z "$currentPolicyType" ]; then
        echo "未能找到SELinux策略类型配置。"
        exit 1
    # 比较当前策略类型与期望值，忽略大小写
    elif [ "$currentPolicyType" != "${expectedPolicyType,,}" ]; then
        echo "检测失败:SELinux策略类型设置不正确。当前策略类型：$currentPolicyType，期望策略类型：$expectedPolicyType。"
        exit 1
    else
        echo "检测成功:SELinux策略配置正确。"
        exit 0
    fi
}

# 调用函数，允许从命令行参数指定期望的SELinux策略类型
check_selinux_policy "$@"
exit $?

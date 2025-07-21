#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Check Script for 3.5.26
#
# #######################################################################################
# 关闭kexec功能
#
# 功能说明：
# - 关闭kexec功能。
# - 提供自测功能。
# #######################################################################################

# 关闭kexec功能
fix_kexec() {
    # 更新/etc/sysctl.conf文件以确保保护配置在重启后仍然生效
    if [ ! -f /etc/sysctl.conf.bak ]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
        echo "备份 /etc/sysctl.conf 为 /etc/sysctl.conf.bak"
    fi

    # 添加或更新配置
    grep -q "^kernel.kexec_load_disabled" /etc/sysctl.conf && sed -i "s/^kernel.kexec_load_disabled.*/kernel.kexec_load_disabled = 1/" /etc/sysctl.conf || echo "kernel.kexec_load_disabled = 1" >> /etc/sysctl.conf

    sysctl -p /etc/sysctl.conf

    echo "修复成功: 已关闭kexec功能。"
}

# 自测部分
self_test() {
    echo "自测: 修复软链接和硬链接保护配置"

    # 临时修改当前会话的保护配置以模拟错误状态
    sysctl -w kernel.kexec_load_disabled=0

    # 运行修复函数
    fix_kexec

    # 检查修复结果
    local kexec_disable=$(sysctl kernel.kexec_load_disabled)

    if [[ "$kexec_disable" == "kernel.kexec_load_disabled = 1" ]]; then
        echo "自测成功: kexec配置已正确修复"
        return 0
    else
        echo "自测失败: kexec配置未正确修复"
        return 1
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [--self-test]"
    echo "选项:"
    echo "  --self-test                进行自测"
    echo "  /?                         显示此帮助信息"
}

# 检查命令行参数
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
elif [[ "$1" == "/?" ]]; then
    show_usage
    exit 0
else
    # 执行修复
    fix_kexec
    exit $?
fi


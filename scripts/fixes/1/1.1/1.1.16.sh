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
# Description: Security Baseline Check Script for 1.1.16
#
# #######################################################################################

# 功能说明:
# 本脚本用于修复软链接和硬链接保护的配置，确保其正确配置以提高系统安全性。

# 修复软链接和硬链接保护的配置
fix_link_protection() {
    local symlink_fix_status=0
    local hardlink_fix_status=0

    sysctl -w fs.protected_symlinks=1
    if [[ $? -ne 0 ]]; then
        echo "修复失败: 无法启用软链接保护。"
        symlink_fix_status=1
    else
        echo "修复成功: 软链接保护已启用。"
    fi

    sysctl -w fs.protected_hardlinks=1
    if [[ $? -ne 0 ]]; then
        echo "修复失败: 无法启用硬链接保护。"
        hardlink_fix_status=1
    else
        echo "修复成功: 硬链接保护已启用。"
    fi

    # 更新/etc/sysctl.conf文件以确保保护配置在重启后仍然生效
    if [ ! -f /etc/sysctl.conf.bak ]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
        echo "备份 /etc/sysctl.conf 为 /etc/sysctl.conf.bak"
    fi

    # 添加或更新配置
    grep -q "^fs.protected_symlinks" /etc/sysctl.conf && sed -i "s/^fs.protected_symlinks.*/fs.protected_symlinks = 1/" /etc/sysctl.conf || echo "fs.protected_symlinks = 1" >> /etc/sysctl.conf
    grep -q "^fs.protected_hardlinks" /etc/sysctl.conf && sed -i "s/^fs.protected_hardlinks.*/fs.protected_hardlinks = 1/" /etc/sysctl.conf || echo "fs.protected_hardlinks = 1" >> /etc/sysctl.conf

    sysctl -p /etc/sysctl.conf

    if [[ $symlink_fix_status -eq 0 && $hardlink_fix_status -eq 0 ]]; then
        echo "软链接和硬链接保护配置已成功修复。"
        return 0
    else
        return 1
    fi
}

# 自测部分
self_test() {
    echo "自测: 修复软链接和硬链接保护配置"

    # 临时修改当前会话的保护配置以模拟错误状态
    sysctl -w fs.protected_symlinks=0
    sysctl -w fs.protected_hardlinks=0

    # 运行修复函数
    fix_link_protection

    # 检查修复结果
    local symlink_protect=$(sysctl fs.protected_symlinks)
    local hardlink_protect=$(sysctl fs.protected_hardlinks)

    if [[ "$symlink_protect" == "fs.protected_symlinks = 1" && "$hardlink_protect" == "fs.protected_hardlinks = 1" ]]; then
        echo "自测成功: 软链接和硬链接保护配置已正确修复"
        return 0
    else
        echo "自测失败: 软链接或硬链接保护配置未正确修复"
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
    SELF_TEST_MODE=true
    self_test
    exit $?
elif [[ "$1" == "/?" ]]; then
    show_usage
    exit 0
else
    # 执行修复
    fix_link_protection
    exit $?
fi


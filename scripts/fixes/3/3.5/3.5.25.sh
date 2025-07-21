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
# Description: Security Baseline Check Script for 3.5.25
#
# #######################################################################################
# 启用内核模块签名功能
#
# 功能说明：
# - 启用内核模块签名功能
# - 提供自测功能。
# #######################################################################################

GRUB_CFG="/boot/efi/EFI/openEuler/grub.cfg"

# 更新内核启动参数以启用内核模块签名功能
update_kernel_params() {
    echo "正在检查内核启动参数..."
    if ! grep -q 'module.sig_enforce' /proc/cmdline; then
        echo "当前未启用内核模块签名功能，正在更新GRUB配置..."
        if [ ! -f "$GRUB_CFG" ]; then
            echo "错误: 找不到 GRUB 配置文件: $GRUB_CFG"
            exit 1
        fi

        sed -i '/linuxefi/s/$/ module.sig_enforce/' "$GRUB_CFG"
        echo "GRUB 配置已更新，请重启系统以生效。"
    else
        echo "内核模块签名功能已启用，无需修改内核启动参数。"
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟配置和验证内核签名功能..."

    # 模拟更新内核启动参数
    echo "模拟更新 GRUB 配置..."
    local test_grub="/tmp/grub.cfg.test"
    cp "$GRUB_CFG" "$test_grub"
    sed -i '/linuxefi/s/$/ module.sig_enforce/' "$test_grub"
    echo "模拟 GRUB 配置已完成，路径: $test_grub"

    if ! grep -q 'module.sig_enforce' $test_grub; then
        echo "自测成功: grub文件已更新。"
    else
        echo "自测失败: grub文件更新失败。"
    fi

    echo "自测完成: 模拟配置成功。"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            echo "使用方法: $0 [--self-test]"
            exit 1
            ;;
    esac
done

# 主修复逻辑
update_kernel_params

exit 0

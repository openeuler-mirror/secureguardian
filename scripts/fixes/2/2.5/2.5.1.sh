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
# Description: Security Baseline Check Script for 2.5.1
#
# #######################################################################################
# 启用 IMA 度量功能并配置相关策略
#
# 功能说明：
# - 自动检查并更新内核启动参数，启用IMA度量功能。
# - 配置默认的 IMA 策略文件。
# - 验证是否正确启用 IMA。
# - 提供自测功能。
# #######################################################################################

GRUB_CFG="/boot/efi/EFI/openEuler/grub.cfg"
IMA_POLICY_FILE="/etc/ima/ima-policy"

# 更新内核启动参数以启用IMA度量功能
update_kernel_params() {
    echo "正在检查内核启动参数..."
    if ! grep -q 'integrity=1' /proc/cmdline; then
        echo "当前未启用IMA度量功能，正在更新GRUB配置..."
        if [ ! -f "$GRUB_CFG" ]; then
            echo "错误: 找不到 GRUB 配置文件: $GRUB_CFG"
            exit 1
        fi

        sed -i '/linuxefi/s/$/ integrity=1 ima_appraise=off evm=ignore/' "$GRUB_CFG"
        echo "GRUB 配置已更新，请重启系统以生效。"
    else
        echo "IMA 度量功能已启用，无需修改内核启动参数。"
    fi
}

# 配置默认的 IMA 策略文件
configure_ima_policy() {
    echo "正在配置 IMA 策略文件..."
    mkdir -p "$(dirname "$IMA_POLICY_FILE")"

    # 添加示例策略
    cat >"$IMA_POLICY_FILE" <<EOF
# 示例 IMA 策略
measure func=BPRM_CHECK
measure func=FILE_CHECK mask=MAY_READ
measure func=FILE_CHECK mask=MAY_WRITE
EOF

    echo "IMA 策略已配置到 $IMA_POLICY_FILE"
}

# 验证 IMA 是否启用且策略是否生效
validate_ima_status() {
    echo "正在验证 IMA 状态..."
    if ! grep -q 'integrity=1' /proc/cmdline; then
        echo "错误: 内核启动参数未正确配置，请确保 integrity=1 生效后重试。"
        exit 1
    fi

    local measurement_count
    measurement_count=$(cat /sys/kernel/security/ima/runtime_measurements_count 2>/dev/null || echo 0)

    if [ "$measurement_count" -le 1 ]; then
        echo "错误: IMA 策略未生效，当前度量记录数为 $measurement_count。"
        exit 1
    fi

    echo "IMA 启用并生效，当前度量记录数为 $measurement_count。"
}

# 自测功能
self_test() {
    echo "开始自测: 模拟配置和验证 IMA 启用..."
    
    # 模拟更新内核启动参数
    echo "模拟更新 GRUB 配置..."
    local test_grub="/tmp/grub.cfg.test"
    cp "$GRUB_CFG" "$test_grub"
    sed -i '/linuxefi/s/$/ integrity=1 ima_appraise=off evm=ignore/' "$test_grub"
    echo "模拟 GRUB 配置已完成，路径: $test_grub"

    # 模拟配置 IMA 策略
    local test_policy="/tmp/ima-policy.test"
    echo "measure func=BPRM_CHECK" >"$test_policy"
    echo "measure func=FILE_CHECK mask=MAY_READ" >>"$test_policy"
    echo "模拟 IMA 策略文件已创建，路径: $test_policy"

    # 检查模拟的 IMA 策略文件
    if [ -f "$test_policy" ]; then
        echo "自测成功: 模拟策略文件已创建，内容如下："
        cat "$test_policy"
    else
        echo "自测失败: 无法创建模拟策略文件。"
        exit 1
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
configure_ima_policy
validate_ima_status

echo "IMA 度量功能已启用并正确配置。请重启系统以完全生效。"
exit 0


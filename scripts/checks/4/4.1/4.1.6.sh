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
# Description: Security Baseline Check Script for 4.1.6
#
# #######################################################################################

# 功能说明:
# 此脚本用于检查是否已正确配置内核模块变更审计规则。
# 它将验证内核模块加载(insmod, modprobe)和卸载(rmmod)操作的审计监控。

function check_kernel_module_audit_rules() {
    local fail_flag=0
    local commands=("/sbin/insmod" "/sbin/rmmod" "/sbin/modprobe")
    local syscalls=("init_module" "delete_module")
    local arch_flag="b64"

    # 检测当前系统是否为64位，如果不是则切换到32位
    if [ "$(getconf LONG_BIT)" = "64" ]; then
        arch_flag="b64"
    else
        arch_flag="b32"
    fi

    # 检查命令相关的审计规则
    for cmd in "${commands[@]}"; do
        local audit_rule=$(auditctl -l | grep -iw "$cmd")
        if [[ -z "$audit_rule" ]]; then
            echo "检测失败: 审计规则未正确配置或未配置用于监控命令 $cmd 的规则。"
            fail_flag=1
        else
            echo "检测成功: 已正确配置监控命令 $cmd 的审计规则。"
            echo "当前规则: $audit_rule"
        fi
    done

    # 检查系统调用相关的审计规则
    for syscall in "${syscalls[@]}"; do
        local syscall_rule=$(auditctl -l | grep -iw "$syscall" | grep "$arch_flag")
        if [[ -z "$syscall_rule" ]]; then
            echo "检测失败: 审计规则未正确配置或未配置用于监控系统调用 $syscall 的规则。"
            fail_flag=1
        else
            echo "检测成功: 已正确配置监控系统调用 $syscall 的审计规则。"
            echo "当前规则: $syscall_rule"
        fi
    done

    return $fail_flag
}

# 调用函数并根据返回值退出脚本
if check_kernel_module_audit_rules; then
    echo "所有内核模块变更审计规则检查通过。"
    exit 0
else
    echo "部分或全部内核模块变更审计规则检查未通过，请检查并配置正确的审计规则。"
    exit 1
fi


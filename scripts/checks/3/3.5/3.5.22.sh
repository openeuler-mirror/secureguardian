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
# Description: Security Baseline Check Script for 3.5.22
#
# #######################################################################################

# 脚本功能说明:
# 本脚本用于检查内核参数 kernel.yama.ptrace_scope 的配置值。
# 用户可以通过参数指定期望的配置值，默认为2。
# 如果内核不支持此配置项，将默认报告检查通过。

# 获取命令行参数
expected_value=${1:-2}  # 如果未提供参数，则默认值为2

# 检测 ptrace_scope 配置
check_ptrace_scope() {
    local current_value=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null)

    # 检查是否能获取到参数值
    if [ -z "$current_value" ]; then
        echo "内核不支持 ptrace_scope 或者 Yama LSM 未启用，检查通过。"
        return 0
    fi

    # 比较当前值与期望值
    if [ "$current_value" -eq "$expected_value" ]; then
        echo "检测成功: 当前 kernel.yama.ptrace_scope 设置值为 $current_value。"
        return 0
    else
        echo "检测失败: ptrace_scope 的配置不符合期望值。当前值为 $current_value，期望值为 $expected_value。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_ptrace_scope; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


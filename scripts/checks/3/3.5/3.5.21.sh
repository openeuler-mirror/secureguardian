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
# Description: Security Baseline Check Script for 3.5.21
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查系统中 SysRq 键的启用状态，确保它被禁用以防止未经授权的系统级命令访问。
# 用户可以通过外部参数自定义期望的配置值，如果未指定参数，默认值为0（禁用SysRq）。

# 使用方法:
# ./script_name [期望值]
# 例如: ./script_name 0

# 获取脚本参数，如果未指定则使用默认值0
expected_value=${1:-0}

check_sysrq() {
    # 检查SysRq的当前设置
    local current_value=$(cat /proc/sys/kernel/sysrq)

    # 输出当前SysRq配置
    echo "当前SysRq设置值: $current_value"

    # 检查当前值是否等于期望值
    if [[ "$current_value" -eq "$expected_value" ]]; then
        echo "检测成功: SysRq 键的配置符合期望值。"
        return 0
    else
        echo "检测失败: SysRq 键的配置不符合期望值。"
        return 1
    fi
}

# 调用检测函数并根据返回值决定脚本退出状态
if check_sysrq; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


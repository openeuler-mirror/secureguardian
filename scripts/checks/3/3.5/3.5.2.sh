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
# Description: Security Baseline Check Script for 3.5.2
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查dmesg访问权限的配置是否正确。
# 确保只有具有CAP_SYSLOG能力的进程可以访问内核日志信息。
# 此脚本检查/etc/sysctl.conf中的kernel.dmesg_restrict是否设置为1。

check_dmesg_restriction() {
    local sysctl_conf="/etc/sysctl.conf"
    local restrict_setting="kernel.dmesg_restrict=1"

    # 检查sysctl配置文件是否包含正确的dmesg限制设置
    if grep -q "^${restrict_setting}" "$sysctl_conf"; then
        echo "dmesg访问权限配置正确。"
        return 0
    else
        echo "检测失败: dmesg访问权限未正确配置。需要设置 $restrict_setting。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_dmesg_restriction; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


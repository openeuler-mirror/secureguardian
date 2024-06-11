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
# Description: Security Baseline Check Script for 3.5.4
#
# #######################################################################################

# 功能说明：
# 这个脚本用于检测系统CPU是否支持SMAP（Supervisor Mode Access Prevention）特性，并确认系统是否已经启用了这一特性。
# SMAP是一种安全特性，用于防止用户模式的应用程序访问内核模式下的内存，增强系统安全。

function check_smap_enabled {
    # 检查CPU是否支持SMAP
    if ! grep -qw smap /proc/cpuinfo; then
        echo "CPU不支持SMAP特性。"
        return 0
    fi

    # 检查启动参数是否禁用了SMAP
    if grep -qi "nosmap" /proc/cmdline; then
        echo "检测失败: SMAP被启动参数禁用。"
        return 1
    fi

    echo "检测成功: SMAP已启用。"
    return 0
}

# 调用检测函数并处理返回值
if check_smap_enabled; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


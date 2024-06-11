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
# Description: Security Baseline Check Script for 3.5.15
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查系统是否开启了记录仿冒、源路由以及重定向报文的日志功能。

check_log_martians() {
    # 检查net.ipv4.conf.all.log_martians的设置
    local log_martians_all=$(sysctl -n net.ipv4.conf.all.log_martians)
    local log_martians_default=$(sysctl -n net.ipv4.conf.default.log_martians)

    # 判断是否都已开启日志记录（应设置为1）
    if [[ "$log_martians_all" -eq 1 && "$log_martians_default" -eq 1 ]]; then
        echo "检测成功: 已启用记录仿冒、源路由以及重定向报文的日志。"
        return 0
    else
        echo "检测失败: 日志记录未完全启用。"
        echo "当前设置：net.ipv4.conf.all.log_martians=$log_martians_all, net.ipv4.conf.default.log_martians=$log_martians_default"
        return 1
    fi
}

# 调用函数并处理返回值
if check_log_martians; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


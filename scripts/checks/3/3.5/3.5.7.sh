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
# Description: Security Baseline Check Script for 3.5.7
#
# #######################################################################################

# 功能说明：
# 本脚本用于检查和确保系统不接收ICMP重定向报文。
# ICMP重定向报文可以被用来恶意修改路由表，导致数据包被错误地发送到攻击者指定的位置。
# 通过检查内核参数确保net.ipv4.conf.all.accept_redirects和net.ipv6.conf.all.accept_redirects都设置为0。

check_icmp_redirects() {
    # 定义变量，用于存储系统配置值
    local ipv4_redirects=$(sysctl -n net.ipv4.conf.all.accept_redirects)
    local ipv6_redirects=$(sysctl -n net.ipv6.conf.all.accept_redirects)
    local ipv4_secure_redirects=$(sysctl -n net.ipv4.conf.all.secure_redirects)
    local ipv4_default_secure_redirects=$(sysctl -n net.ipv4.conf.default.secure_redirects)

    # 检查所有相关配置是否设置为0
    if [[ "$ipv4_redirects" == "0" && "$ipv6_redirects" == "0" && "$ipv4_secure_redirects" == "0" && "$ipv4_default_secure_redirects" == "0" ]]; then
        echo "检测成功: 系统已正确配置不接收任何ICMP重定向报文。"
        return 0
    else
        echo "检测失败: 一项或多项ICMP重定向报文接收设置未正确配置。"
        return 1
    fi
}

# 调用检查函数并处理返回值
if check_icmp_redirects; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


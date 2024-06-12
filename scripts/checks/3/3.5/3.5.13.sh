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
# Description: Security Baseline Check Script for 3.5.13
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查系统是否禁用了源路由，这是网络安全的一项重要措施。

check_source_routing() {
    # 检查IPv4源路由设置
    local ipv4_src_route=$(sysctl -n net.ipv4.conf.all.accept_source_route)
    local ipv4_default_src_route=$(sysctl -n net.ipv4.conf.default.accept_source_route)

    # 检查IPv6源路由设置
    local ipv6_src_route=$(sysctl -n net.ipv6.conf.all.accept_source_route)
    local ipv6_default_src_route=$(sysctl -n net.ipv6.conf.default.accept_source_route)

    # 判断源路由是否被禁用（应设置为0）
    if [[ "$ipv4_src_route" -eq 0 && "$ipv4_default_src_route" -eq 0 && "$ipv6_src_route" -eq 0 && "$ipv6_default_src_route" -eq 0 ]]; then
        echo "检测成功: 所有IPv4和IPv6源路由设置已被禁用。"
        return 0
    else
        echo "检测失败: 源路由设置未完全禁用。IPv4: $ipv4_src_route/$ipv4_default_src_route, IPv6: $ipv6_src_route/$ipv6_default_src_route。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_source_routing; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


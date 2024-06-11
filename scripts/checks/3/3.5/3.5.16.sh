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
# Description: Security Baseline Check Script for 3.5.16
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查系统是否已禁用tcp_timestamps，以减少潜在的网络攻击风险。

check_tcp_timestamps() {
    # 检查tcp_timestamps的设置
    local tcp_timestamps=$(sysctl -n net.ipv4.tcp_timestamps)

    # 判断是否已关闭tcp_timestamps（应设置为0）
    if [[ "$tcp_timestamps" -eq 0 ]]; then
        echo "检测成功: 已禁用tcp_timestamps。"
        return 0
    else
        echo "检测失败: tcp_timestamps未被禁用。当前设置值为：$tcp_timestamps"
        return 1
    fi
}

# 调用函数并处理返回值
if check_tcp_timestamps; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


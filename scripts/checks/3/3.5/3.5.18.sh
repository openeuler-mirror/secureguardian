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
# Description: Security Baseline Check Script for 3.5.18
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查系统的 tcp_max_syn_backlog 设置，以确保TCP SYN接收队列的大小适当配置。
# 可通过参数自定义推荐值，如果未指定，将使用默认值256。

# 使用方法:
# ./script_name [推荐值]
# 例如: ./script_name 512

# 获取脚本参数，如果未指定则使用默认值256
recommended_value=${1:-256}

check_syn_recv_queue() {
    # 获取当前tcp_max_syn_backlog的设置值
    local current_value=$(sysctl -n net.ipv4.tcp_max_syn_backlog)

    # 检查当前值是否等于推荐值
    if [[ "$current_value" -eq "$recommended_value" ]]; then
        echo "检测成功: tcp_max_syn_backlog已设置为推荐值，当前值为：$current_value。"
        return 0
    else
        echo "检测失败: tcp_max_syn_backlog未设置为推荐值，当前值为：$current_value，建议设置为$recommended_value。"
        return 1
    fi
}

# 调用检测函数并根据返回值决定脚本退出状态
if check_syn_recv_queue; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


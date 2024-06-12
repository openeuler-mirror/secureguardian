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
# Description: Security Baseline Check Script for 4.1.1
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查 auditd 审计系统的状态。
# 此外，脚本还验证 auditd 服务是否设置为开机自启。

# 函数：检查 auditd 服务状态和启用状态
check_auditd_status() {
    # 检查 auditd 服务是否启动
    local service_active=$(systemctl is-active auditd.service)
    if [ "$service_active" != "active" ]; then
        echo "检测失败: auditd 服务未运行。"
        return 1
    fi

    # 检查 auditd 服务是否设为开机启动
    local service_enabled=$(systemctl is-enabled auditd.service)
    if [ "$service_enabled" != "enabled" ]; then
        echo "检测失败: auditd 服务未设置为开机自启。"
        return 1
    fi

    echo "检测成功: auditd 服务已启用并正在运行。"
    return 0
}

# 调用检查函数并处理返回值
if check_auditd_status; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


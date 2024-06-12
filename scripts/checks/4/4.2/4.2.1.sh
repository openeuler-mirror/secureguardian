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
# Description: Security Baseline Check Script for 4.2.1
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查 rsyslog 审计系统的状态。它确保 rsyslog 服务已启动且设置为开机自启。
# 使用此脚本有助于维护系统安全和合规性，特别是在对系统日志进行持久存储的环境中。

check_rsyslog_service() {
    # 检查rsyslog服务是否启用
    local enabled=$(systemctl is-enabled rsyslog.service 2>/dev/null)
    if [ "$enabled" != "enabled" ]; then
        echo "检测失败: rsyslog服务未设置为启动。"
        return 1
    fi

    # 检查rsyslog服务是否正在运行
    local active=$(systemctl is-active rsyslog.service)
    if [ "$active" != "active" ]; then
        echo "检测失败: rsyslog服务未运行。"
        return 1
    fi

    echo "检查通过: rsyslog服务已启用并正在运行。"
    return 0
}


# 调用函数并处理返回值
if check_rsyslog_service; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


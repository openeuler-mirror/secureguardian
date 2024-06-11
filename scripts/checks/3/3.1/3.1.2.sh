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
# Description: Security Baseline Check Script for 3.1.2
#
# #######################################################################################

# 函数：检查无线网络状态
check_wireless_status() {
    local wifi_status
    local wwan_status

    # 使用nmcli工具获取无线设备的状态
    read wifi_status wwan_status <<< $(nmcli radio all | awk 'NR==2 {print $2, $4}')

    # 根据参数决定是否需要反转逻辑
    if [[ $1 == "enabled" ]]; then
        if [[ $wifi_status == "enabled" || $wwan_status == "enabled" ]]; then
            echo "检测失败: WIFI或WWAN至少一个已启用。"
            return 1
        fi
    else
        if [[ $wifi_status == "disabled" && $wwan_status == "disabled" ]]; then
            echo "检测成功: 无线网络已被禁用。"
            return 0
        else
            echo "检测失败: 无线网络未完全禁用。"
            return 1
        fi
    fi
}

# 帮助信息
show_usage() {
    echo "用法：$0 [-e|-d] (检查无线网络是启用还是禁用)"
    echo "选项："
    echo "  -e 检查无线网络是否启用"
    echo "  -d 检查无线网络是否禁用"
    echo "不带选项时默认检查无线网络是否禁用"
}

# 参数解析
while getopts ":ed?" opt; do
    case $opt in
        e)
            check_mode="enabled"
            ;;
        d)
            check_mode="disabled"
            ;;
        ?)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# 执行检查
check_wireless_status $check_mode
exit $?

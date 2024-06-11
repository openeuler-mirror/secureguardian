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
# Description: Security Baseline Check Script for 4.2.5
#
# #######################################################################################

# 功能说明:
# 此脚本用于检查系统日志配置，确保特定服务的日志记录被正确配置。
# 支持短参数输入，方便用户指定服务名和日志文件路径。

function show_usage {
    echo "Usage: $0 -s <service_name> -l <logfile_path>"
    echo "Example: $0 -s cron -l /var/log/cron"
    echo "未提供参数，忽略检查。"
}

function check_log_config {
    local service=$1
    local logfile=$2
    local config_files="/etc/rsyslog.conf /etc/rsyslog.d/*.conf"
    local found=0

    # 搜索指定的日志配置
    for config_file in $config_files; do
        if grep -qE "$service.*$logfile" "$config_file"; then
            echo "检查成功: '$service' 日志配置为 '$logfile' 在文件 '$config_file'"
            found=1
            break
        fi
    done

    if [ $found -ne 1 ]; then
        echo "检测失败: 未找到服务 '$service' 的日志配置指向 '$logfile'"
        return 1
    fi

    return 0
}

# 默认参数
service=""
logfile=""

# 参数解析
while getopts ":s:l:" opt; do
    case $opt in
        s) service="$OPTARG";;
        l) logfile="$OPTARG";;
        \?) show_usage
            exit 1;;
    esac
done

# 如果没有提供参数，则跳过检查并成功退出
if [ -z "$service" ] || [ -z "$logfile" ]; then
    show_usage
    exit 0
fi

# 调用函数并处理返回值
if check_log_config "$service" "$logfile"; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


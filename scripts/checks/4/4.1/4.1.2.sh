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
# Description: Security Baseline Check Script for 4.1.2
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查 auditd 配置文件中的日志轮转设置。
# 它检查 max_log_file_action 和 num_logs 设置以确保日志轮转已正确启用。
# 这有助于保证在日志文件达到上限时，系统能按照预期管理旧的日志文件。

# 默认设置
expected_action="ROTATE"
expected_num_logs_min=5  # 最少要有两个日志文件允许轮转

# 使用 getopts 解析命令行参数
while getopts ":a:n:?" opt; do
    case "$opt" in
        a)
            expected_action=$OPTARG
            ;;
        n)
            expected_num_logs_min=$OPTARG
            ;;
        \?)
            echo "使用方式: $0 [-a action] [-n num_logs]"
            echo "  -a 设置期望的max_log_file_action，默认为ROTATE"
            echo "  -n 设置期望的最小num_logs，默认为5"
            exit 0
            ;;
        *)
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

function check_audit_rotate() {
    local config_file="/etc/audit/auditd.conf"
    local max_action=$(grep -i "^max_log_file_action" $config_file | awk -F= '{print $2}' | tr -d ' ')
    local num_logs=$(grep -i "^num_logs" $config_file | awk -F= '{print $2}' | tr -d ' ')

    if [[ "$max_action" != "$expected_action" || "$num_logs" -lt "$expected_num_logs_min" ]]; then
        echo "检测失败: 审计日志轮转未正确配置。"
        echo "当前设置: max_log_file_action=$max_action, num_logs=$num_logs"
        echo "建议设置: max_log_file_action=$expected_action, num_logs至少为$expected_num_logs_min"
        return 1
    else
        echo "检测成功: 审计日志轮转已正确配置。"
        return 0
    fi
}


# 调用检查函数并处理返回值
if check_audit_rotate; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi

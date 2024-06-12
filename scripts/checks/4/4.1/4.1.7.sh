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
# Description: Security Baseline Check Script for 4.1.7
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查系统中是否已配置针对名为 'sudo.log' 的文件的审计规则。
# 用户可以通过参数指定要检查的日志文件名。

function usage() {
    echo "Usage: $0 [-f logfile]"
    echo "  -f  指定要检查的日志文件路径，默认为 /var/log/sudo.log"
}

function check_sudo_audit_rules() {
    local logfile=$1
    local audit_rule=$(auditctl -l | grep -i "$logfile")

    if [[ -z "$audit_rule" ]]; then
        echo "检测失败: 未配置用于监控文件 '$logfile' 的审计规则。"
        return 1
    else
        echo "检测成功: 已配置监控文件 '$logfile' 的审计规则。"
        echo "当前规则: $audit_rule"
        return 0
    fi
}

# 默认日志文件路径
logfile="/var/log/sudo.log"

# 解析命令行参数
while getopts ":f:?" opt; do
    case "$opt" in
        f)
            logfile="$OPTARG"
            ;;
        \?)
            usage
            exit 0
            ;;
        *)
            echo "无效选项: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# 调用函数并处理返回值
if check_sudo_audit_rules "$logfile"; then
    echo "管理员特权操作审计规则检查通过。"
    exit 0
else
    echo "管理员特权操作审计规则检查未通过，请检查并配置正确的审计规则。"
    exit 1
fi


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
# Description: Security Baseline Check Script for 4.1.9
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查是否已正确配置audit_backlog_limit参数。
# 它通过检查内核启动参数来确定audit_backlog_limit是否设置且值是否合理。

# 使用方法说明
usage() {
    echo "使用方法: $0 [-m <number> | --min-limit <number>]"
    echo "示例: $0 --min-limit 8192"
    echo "       $0 -m 8192"
    exit 1
}

# 解析命令行参数
min_limit=8192  # 默认的最小限制值
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -m | --min-limit )
    shift; min_limit=$1
    ;;
  -h | --help )
    usage
    ;;
  * )
    echo "无效参数: $1"
    usage
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# 检查audit_backlog_limit配置
check_audit_backlog_limit() {
    local cmdline=$(cat /proc/cmdline)
    local pattern="audit_backlog_limit=${min_limit}"

    if echo "$cmdline" | grep -q "$pattern"; then
        echo "检测成功: audit_backlog_limit已正确配置为${min_limit}或更高。"
        return 0
    else
        echo "检测失败: audit_backlog_limit未正确配置为${min_limit}或更高。"
        return 1
    fi
}

# 执行检查
check_audit_backlog_limit


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
# Description: Security Baseline Check Script for 4.1.4
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查系统中是否已正确配置账号信息修改审计规则。
# 它将验证 /etc/passwd, /etc/group, /etc/shadow, /etc/gshadow, 和 /etc/security/opasswd 文件的审计规则。
# 这些文件包含关键的用户账号和认证信息，对它们的修改应当被审计以便于事后追踪和安全管理。

function check_audit_rules_for_important_files() {
    local files=("/etc/passwd" "/etc/group" "/etc/shadow" "/etc/gshadow" "/etc/security/opasswd")
    local fail_flag=0

    # 读取 auditctl 输出
    auditctl_output=$(auditctl -l)

    for file in "${files[@]}"; do
        # 正则表达式匹配 "-w 文件 -p wa"，考虑到可能的多余空格
        local regex="-w\s+$file\s+-p\s+wa"
        if [[ ! "$auditctl_output" =~ $regex ]]; then
            echo "检测失败: 审计规则未正确配置或未配置用于监控文件 $file 的规则。"
            fail_flag=1
        else
            echo "检测成功: 已正确配置监控文件 $file 的审计规则。"
        fi
    done

    return $fail_flag
}

# 解析命令行参数
while getopts ":?" opt; do
    case "$opt" in
        \?)
            echo "使用方式: $0"
            echo "此脚本无需参数，直接执行即可检查是否已正确配置账号信息修改审计规则。"
            exit 0
            ;;
        *)
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# 调用函数并根据返回值退出脚本
if check_audit_rules_for_important_files; then
    echo "所有关键文件审计规则检查通过。"
    exit 0
else
    echo "部分或全部关键文件审计规则检查未通过，请检查并配置正确的审计规则。"
    exit 1
fi


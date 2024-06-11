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
# Description: Security Baseline Check Script for 2.2.7
#
# #######################################################################################

# 设置默认参数
max_days=${1:-90}
warn_age=${2:-7}
min_days=${3:-0}

# 定义需要排除的用户列表
exclude_users=("sync" "halt" "shutdown" "bin" "daemon" "rpc" "adm" "lp" "mail" "operator" "games" "ftp" "nobody")

# 检查 /etc/login.defs 配置
check_login_defs() {
    local max_days_actual=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{ print $2 }')
    local warn_age_actual=$(grep "^PASS_WARN_AGE" /etc/login.defs | awk '{ print $2 }')
    local min_days_actual=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{ print $2 }')

    if [ "$max_days_actual" -gt "$max_days" ]; then
        echo "检测失败: /etc/login.defs 口令最大有效期设置为$max_days_actual天，应该设置为$max_days天或更短。"
        return 1
    fi

    if [ "$warn_age_actual" -lt "$warn_age" ]; then
        echo "检测失败: /etc/login.defs 口令过期前提醒设置为$warn_age_actual天，应该设置为$warn_age天或更长。"
        return 1
    fi

    if [ "$min_days_actual" -lt "$min_days" ]; then
        echo "警告: /etc/login.defs 两次修改口令的最小间隔时间设置为$min_days_actual天，建议设置为$min_days天。"
    fi

    echo "/etc/login.defs 配置检查完成。"
}

# 检查 /etc/shadow 中的用户口令有效期
check_users_password_age() {
    local fail=0
    while IFS=':' read -r user enc_pw last_change min_age max_age warn_age inactive expire reserved; do
        # 检查用户是否在排除列表中或者是特定的系统用户
        if [[ " ${exclude_users[@]} " =~ " ${user} " ]]; then
            continue
        fi

        # 如果max_age或warn_age为空，则跳过此用户的检查
        if [[ -z "$max_age" || -z "$warn_age" ]]; then
            continue
        fi

        # 检查max_days
        if [ "$max_age" -gt "$max_days" ]; then
            echo "用户 $user 口令最大有效期设置为$max_age天，超过了$max_days天的建议设置。"
            fail=1
        fi

        # 检查warn_age
        if [ "$warn_age" -lt "$warn_age" ]; then
            echo "用户 $user 口令过期前提醒设置为$warn_age天，小于建议的$warn_age天。"
            fail=1
        fi
    done </etc/shadow

    if [ "$fail" -eq 1 ]; then
        echo "部分用户口令有效期设置不符合要求。"
        return 1
    else
        echo "所有检查的用户口令有效期设置均符合要求。"
    fi
}

# 主函数
main() {
    check_login_defs
    local login_defs_result=$?
    
    check_users_password_age
    local users_password_age_result=$?

    if [ $login_defs_result -ne 0 ] || [ $users_password_age_result -ne 0 ]; then
        echo "存在配置不符合要求。"
        exit 1
    else
        echo "所有检查均通过。"
        exit 0
    fi
}

main "$@"


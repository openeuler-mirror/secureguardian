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
# Description: Security Baseline Check Script for 2.2.2
#
# #######################################################################################

# 函数：检查是否禁用了历史口令重用
check_history_passwords() {
    # 默认的历史口令次数
    local remember_times=5
    local file_paths=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
    local found_issues=0

    # 解析命令行参数
    while getopts "r:" opt; do
        case $opt in
            r) remember_times="$OPTARG" ;;
            \?) echo "无效的选项: -$OPTARG" >&2; exit 1 ;;
        esac
    done

    # 检查配置文件
    for file_path in "${file_paths[@]}"; do
        if [ ! -f "$file_path" ]; then
            echo "警告: 配置文件 $file_path 未找到。"
            continue
        fi

        # 使用grep检查remember值，排除被注释的行
        while IFS= read -r line; do
            if [[ $line =~ pam_pwhistory\.so ]] && ! [[ $line =~ ^\# ]]; then
                # 提取记住的密码次数
                local current_remember=$(echo "$line" | grep -oP "remember=\K\d+")
                if [[ -z "$current_remember" ]] || [[ "$current_remember" -lt "$remember_times" ]]; then
                    echo "检测失败: $file_path 中的 remember 值设置小于 $remember_times 或该设置被注释。"
                    found_issues=$((found_issues+1))
                else
                    echo "$file_path 中的 remember 值符合要求。"
                fi
            fi
        done < "$file_path"
    done

    # 根据检查结果返回状态
    if [ "$found_issues" -ne 0 ]; then
        return 1  # 存在问题
    else
        echo "所有配置文件均符合历史口令禁用要求。"
        return 0  # 检查通过
    fi
}

# 调用函数并处理返回值
if check_history_passwords "$@"; then
    exit 0  # 检查通过，脚本成功退出
else
    echo "存在配置不符合要求。"
    exit 1  # 检查未通过
fi


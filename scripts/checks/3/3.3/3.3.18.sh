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
# Description: Security Baseline Check Script for 3.3.18
#
# #######################################################################################

# 脚本用来检查是否有预设置的 authorized_keys 文件，除非特别允许

usage() {
    echo "Usage: $0 [-e <exceptions>]"
    echo "  -e, --exceptions   Comma-separated list of directories to exclude from the check"
    echo "  -h, --help         Display this help message"
}

# 解析命令行参数
EXCEPTIONS=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--exceptions) EXCEPTIONS="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# 将逗号分隔的例外转换为find命令的排除参数
EXCLUDES=""
if [[ -n "$EXCEPTIONS" ]]; then
    IFS=',' read -r -a dirs <<< "$EXCEPTIONS"
    for dir in "${dirs[@]}"; do
        # 添加通配符以确保匹配所有子目录
        EXCLUDES+=" ! -path \"$dir/*\" ! -path \"$dir\""
    done
fi

# 定义检查函数
check_authorized_keys() {
    local found_files=0

    # 使用find命令查找所有用户主目录中的authorized_keys文件，排除例外
    local files=$(eval "find /home/ /root/ -name authorized_keys $EXCLUDES 2>/dev/null")

    if [[ -n "$files" ]]; then
        echo "检测到未授权的 authorized_keys 文件:"
        echo "$files"
        found_files=1
    else
        echo "未检测到未授权的 authorized_keys 文件。"
    fi

    return $found_files
}

# 调用检查函数并处理结果
if check_authorized_keys; then
    exit 0  # 未找到文件，检查通过
else
    echo "检测失败: 系统中预设置了 unauthorized_keys 文件。"
    exit 1  # 找到文件，检查未通过
fi


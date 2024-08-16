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
# Description: Security Baseline Check Script for 1.1.13
#
# #######################################################################################

# 功能说明:
# 本脚本用于检测并修复系统中不必要的SUID和SGID位文件。通过移除这些文件的SUID和SGID位，提高系统安全性。

# 检测并修复系统中不必要的SUID/SGID位设置的文件
fix_unnecessary_suid_sgid() {
    local exceptions=()
    local specific_file=""

    # 解析输入参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--exception)
                exceptions+=("$2")
                shift
                shift
                ;;
            -f|--file)
                specific_file="$2"
                shift
                shift
                ;;
            /?)
                show_usage
                return 0
                ;;
            *)
                echo "未知参数: $1"
                show_usage
                return 1
                ;;
        esac
    done

    local issue_found=0
    local file_list

    if [[ -n "$specific_file" ]]; then
        file_list=$(find / -type f \( -perm -4000 -o -perm -2000 \) -wholename "$specific_file")
    else
        file_list=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type f \( -perm -4000 -o -perm -2000 \) -print)
    fi

    while IFS= read -r file; do
        # 检查是否在例外列表中
        if [[ " ${exceptions[@]} " =~ " ${file} " ]]; then
            continue
        fi

        echo "发现不必要的SUID/SGID文件：$file"
        issue_found=1

        # 移除文件的SUID和SGID位
        chmod u-s,g-s "$file"
        if [[ $? -ne 0 ]]; then
            echo "修复失败: 无法移除文件 $file 的SUID/SGID位"
            return 1
        else
            echo "修复成功: 已移除文件 $file 的SUID/SGID位"
        fi
    done < <(echo "$file_list")

    if [ $issue_found -eq 0 ]; then
        echo "系统中不存在不必要的SUID/SGID位设置，或者指定的文件已被正确排除。"
    fi

    return 0  # 所有检测均通过
}

# 自测部分
self_test() {
    # 创建测试文件
    touch /tmp/testfile
    chmod u+s /tmp/testfile
    chmod g+s /tmp/testfile

    echo "自测: 创建了一个测试文件 /tmp/testfile 并设置了SUID和SGID位"

    # 运行修复函数
    fix_unnecessary_suid_sgid -f /tmp/testfile

    # 检查自测结果
    if [[ $(find /tmp/testfile -perm -4000 -o -perm -2000) ]]; then
        echo "自测失败: 测试文件 /tmp/testfile 的SUID/SGID位未被移除"
        rm -f /tmp/testfile
        return 1
    else
        echo "自测成功: 测试文件 /tmp/testfile 的SUID/SGID位已被移除"
        rm -f /tmp/testfile
        return 0
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -e, --exception <文件>       指定例外的文件，可以多次使用"
    echo "  -f, --file <文件>            只检测指定的文件"
    echo "  /?                          显示此帮助信息"
}

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
else
    # 调用修复函数并处理返回值
    fix_unnecessary_suid_sgid "$@"
    exit $?
fi


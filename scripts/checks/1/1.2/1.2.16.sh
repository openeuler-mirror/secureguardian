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
# Description: Security Baseline Check Script for 1.2.16
#
# #######################################################################################

# 定义可能需要检测的调试工具列表
debug_tools="strace gdb readelf perf binutils appict kmem_analyzer_tools"

# 检测调试工具的RPM包是否已安装
check_debug_tools_rpm() {
    local installed_tools=()

    for tool in $debug_tools; do
        if rpm -qa | grep -qiE "^($tool-)"; then
            installed_tools+=($tool)
        fi
    done

    if [ ${#installed_tools[@]} -gt 0 ]; then
        echo "检测不通过。已安装的调试工具RPM包: ${installed_tools[*]}"
        return 1
    else
        echo "RPM包检测通过。未安装调试工具。"
        return 0
    fi
}

# 检测是否存在调试工具的命令
check_debug_tools_files() {
    local found_tools=()
    local find_cmd="find / -type f"

    for tool in $debug_tools; do
        find_cmd="$find_cmd -o -name $tool"
    done

    find_cmd="$find_cmd 2>/dev/null"

    while IFS= read -r path; do
        if file "$path" | grep -qi "ELF"; then
            found_tools+=("$path")
        fi
    done < <(eval "$find_cmd")

    if [ ${#found_tools[@]} -gt 0 ]; then
        echo "检测不通过。发现安装的调试工具: ${found_tools[*]}"
        return 1
    else
        echo "文件检测通过。未发现安装的调试工具。"
        return 0
    fi
}

# 执行检查
check_debug_tools_rpm
rpm_check_result=$?

#check_debug_tools_files
#file_check_result=$?

# 汇总检查结果
#if [ $rpm_check_result -ne 0 ] || [ $file_check_result -ne 0 ]; then
if [ $rpm_check_result -ne 0 ]; then
    #echo "总检测不通过。存在调试工具。"
    exit 1
else
    #echo "总检测通过。"
    exit 0
fi


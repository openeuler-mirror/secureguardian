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
# Description: Security Baseline Check Script for 1.2.17
#
# #######################################################################################

# 定义可能需要检测的开发编译类工具列表
compile_tools="gcc cpp mcpp flex cmake make rpm-build binutils-extra elfutils-extra llvm rpcgen gcc-c++ libtool javac objdump eu-objdump eu-readelf nm"

# 检测开发编译类工具的RPM包是否已安装
check_compile_tools_rpm() {
    local installed_tools=()

    for tool in $compile_tools; do
        if rpm -qa | grep -qiE "^($tool-)"; then
            installed_tools+=($tool)
        fi
    done

    if [ ${#installed_tools[@]} -gt 0 ]; then
        echo "检测不通过。已安装的开发编译类工具RPM包: ${installed_tools[*]}"
        return 1
    else
        echo "RPM包检测通过。未安装开发编译类工具。"
        return 0
    fi
}

#!/bin/bash

# 定义可能需要检测的开发编译类工具列表
compile_tools=(
    gcc
    g++
    c++
    cpp
    mcpp
    flex
    lex
    cmake
    make
    rpmbuild
    ld
    ar
    llc
    rpcgen
    libtool
    javac
    objdump
    eu-objdump
    eu-readelf
    nm
)

# 检测开发编译类工具的RPM包是否已安装
check_compile_tools_rpm() {
    local installed_tools=()

    for tool in "${compile_tools[@]}"; do
        if rpm -qa | grep -qiE "^($tool-)"; then
            installed_tools+=("$tool")
        fi
    done

    if [ ${#installed_tools[@]} -gt 0 ]; then
        echo "检测不通过。已安装的开发编译类工具RPM包: ${installed_tools[*]}"
        return 1
    else
        echo "RPM包检测通过。未安装开发编译类工具。"
        return 0
    fi
}

# 执行检查
check_compile_tools_rpm
rpm_check_result=$?

#速度太慢,暂时屏蔽
#check_compile_tools_files
#file_check_result=$?

# 汇总检查结果
#if [ $rpm_check_result -ne 0 ] || [ $file_check_result -ne 0 ]; then
if [ $rpm_check_result -ne 0 ]; then
    #echo "总检测不通过。存在开发编译类工具。"
    exit 1
else
    #echo "总检测通过。"
    exit 0
fi


#!/bin/bash
## #######################################################################################
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
# Description: Security Baseline Check Script for 1.1.14
#
# #######################################################################################

# 功能说明:
# 本脚本用于检测并修复系统中关键文件和目录的权限设置，确保其符合最小化权限要求。通过正确设置文件和目录权限，减少信息泄露和提权风险。

# 定义期望的权限设置
declare -A expected_permissions=(
    ["/etc/passwd"]="644"
    ["/etc/group"]="644"
    ["/etc/shadow"]="000"
    ["/etc/gshadow"]="000"
    ["/etc/passwd-"]="644"
    ["/etc/shadow-"]="000"
    ["/etc/group-"]="644"
    ["/etc/gshadow-"]="000"
    ["/etc/ssh/sshd_config"]="600"
    # 添加更多文件和期望的权限
)

# 检测并修复关键文件和目录的权限设置
fix_min_permissions() {
    local issue_found=0

    for path in "${!expected_permissions[@]}"; do
        # 检查文件或目录是否存在
        if [ ! -e "$path" ]; then
            echo "Warning: $path does not exist."
            continue
        fi

        # 获取文件的实际权限并格式化为三位数
        actual_perm=$(stat -c "%a" "$path" | awk '{printf "%03d", $0}')

        # 对比实际权限和期望权限
        if [ "$actual_perm" != "${expected_permissions[$path]}" ]; then
            echo "Permission issue: $path (Expected: ${expected_permissions[$path]}, Actual: $actual_perm)"
            issue_found=1

            # 修复权限
            chmod "${expected_permissions[$path]}" "$path"
            if [[ $? -ne 0 ]]; then
                echo "修复失败: 无法修改 $path 的权限"
                return 1
            else
                echo "修复成功: $path 的权限已修改为 ${expected_permissions[$path]}"
            fi
        fi
    done

    if [ $issue_found -eq 0 ]; then
        echo "所有检测的文件和目录权限设置正确。"
    fi

    return 0
}

# 自测部分
self_test() {
    # 创建测试文件和目录
    touch /tmp/testfile
    mkdir /tmp/testdir

    # 设置错误权限
    chmod 777 /tmp/testfile
    chmod 777 /tmp/testdir

    echo "自测: 创建了测试文件 /tmp/testfile 和测试目录 /tmp/testdir，并设置了错误权限"

    # 运行修复函数
    expected_permissions["/tmp/testfile"]="640"
    expected_permissions["/tmp/testdir"]="750"
    fix_min_permissions

    # 检查自测结果
    testfile_perm=$(stat -c "%a" /tmp/testfile)
    testdir_perm=$(stat -c "%a" /tmp/testdir)

    if [[ "$testfile_perm" == "640" && "$testdir_perm" == "750" ]]; then
        echo "自测成功: 测试文件和目录的权限已正确修复"
        rm -f /tmp/testfile
        rm -rf /tmp/testdir
        return 0
    else
        echo "自测失败: 测试文件或目录的权限未正确修复"
        rm -f /tmp/testfile
        rm -rf /tmp/testdir
        return 1
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  /?                          显示此帮助信息"
}

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
else
    # 调用修复函数并处理返回值
    fix_min_permissions
    exit $?
fi


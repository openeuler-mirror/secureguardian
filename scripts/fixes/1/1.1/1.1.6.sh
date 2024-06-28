#!/bin/bash

# #######################################################################################
#
# Copyright (c) SecureGuardian.
# All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline fix Script for 1.1.6
#
# #######################################################################################

# 功能说明:
# 本脚本用于查找并修复系统中所有全局可写的文件。

# 定义检查并修复全局可写文件的函数
fix_global_writable_files() {

    # 搜索全局可写文件，排除 /proc 和 /sys 目录
    find / -path /proc -prune -o -path /sys -prune -o -type f -perm -0002 -print0 | while IFS= read -r -d $'\0' file; do
        echo "发现全局可写文件: $file"
        chmod o-w "$file"
        echo "已修改权限: $file"
    done

    echo "全局可写文件修复完成。"
}

# 自测部分
self_test() {
    # 创建测试文件
    touch /tmp/test_global_writable
    chmod 777 /tmp/test_global_writable

    echo "自测: 创建全局可写测试文件 /tmp/test_global_writable"
    ls -l /tmp/test_global_writable

    # 运行修复函数
    fix_global_writable_files

    # 验证修复
    echo "自测验证修复:"
    ls -l /tmp/test_global_writable

    # 清理测试文件
    rm /tmp/test_global_writable
}

# 主执行逻辑
if [[ "$1" == "/?" ]]; then
    echo "用法：./1.1.6.sh [--self-test]"
    echo "  --self-test     进行脚本自检"
    exit 0
elif [[ "$1" == "--self-test" ]]; then
    self_test
else
    fix_global_writable_files
fi

exit $?


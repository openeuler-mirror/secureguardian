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
# Description: Security Baseline Check Script for 3.1.1
#
# #######################################################################################

# 显示使用说明
show_usage() {
    echo "用法：$0 -m [模块名]"
    echo "例如：$0 -m sctp 或 $0 -m tipc"
    echo "如果没有提供模块名，将检查 sctp 和 tipc"
}

# 检查指定的模块是否被禁用
check_module_disabled() {
    local module=$1
    local output=$(modprobe -n -v $module 2>&1)
    
    if [[ $output == *"install /bin/true"* ]]; then
        echo "模块 $module 已被正确禁用。"
        return 0
    else
        echo "检测失败: 模块 $module 未被禁用。详细输出：$output"
        return 1
    fi
}

# 解析命令行参数
while getopts "m:?" opt; do
    case $opt in
        m)
            module="$OPTARG"
            ;;
        ?)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# 设置默认模块名称
if [[ -z $module ]]; then
    module_list=("sctp" "tipc")
else
    module_list=($module)
fi

# 检查模块
failure=0
for mod in "${module_list[@]}"; do
    check_module_disabled $mod || failure=1
done

# 根据检查结果退出
if [ $failure -eq 0 ]; then
    exit 0
else
    exit 1
fi


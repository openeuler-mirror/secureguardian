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
# Description: Security Baseline Check Script for 1.1.15
#
# #######################################################################################

# 接受命令行参数或使用默认值
expected_soft_limit=${1:-2000}
expected_hard_limit=${2:-524288}

# 读取当前的软限制和硬限制
current_soft_limit=$(ulimit -Sn)
current_hard_limit=$(ulimit -Hn)

# 检查软限制是否设置正确
check_soft_limit() {
    if [ "$current_soft_limit" -gt "$expected_soft_limit" ]; then
        echo "警告: 当前软限制值 $current_soft_limit 高于限值 $expected_soft_limit。"
        return 1
    else
        echo "软限制值 $current_soft_limit 符合或低于限值。"
	return 0
    fi
}

# 检查硬限制是否设置正确
check_hard_limit() {
    if [ "$current_hard_limit" -gt "$expected_hard_limit" ]; then
        echo "警告: 当前硬限制值 $current_hard_limit 高于限值 $expected_hard_limit。"
        return 1
    else
        echo "硬限制值 $current_hard_limit 符合或低于限值。"
	return 0
    fi
}

# 执行检查并处理结果
check_errors=0

check_soft_limit || check_errors=1
check_hard_limit || check_errors=1

if [ "$check_errors" -eq 0 ]; then
    #echo "所有打开文件数量限制的配置均符合或低于限。"
    exit 0
else
    #echo "存在配置不合理的项目，请根据提示进行调整。"
    exit 1
fi



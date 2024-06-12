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
# Description: Security Baseline Check Script for 2.4.10
#
# #######################################################################################

# 定义检查标签为unconfined_service_t的进程的函数
check_unconfined_service_t_processes() {
    # 使用ps和grep命令检查是否存在标签为unconfined_service_t的进程
    if ps -eZ | grep -q 'unconfined_service_t'; then
        echo "检测失败: 系统中存在标签为unconfined_service_t的进程。"
        # 打印具体的进程信息以便进一步分析
        ps -eZ | grep 'unconfined_service_t'
        return 1
    else
        echo "检测成功: 系统中没有标签为unconfined_service_t的进程。"
        return 0
    fi
}

# 调用检查函数
check_unconfined_service_t_processes
exit $?


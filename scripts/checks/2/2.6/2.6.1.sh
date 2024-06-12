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
# Description: Security Baseline Check Script for 2.6.1
#
# #######################################################################################

# 检查haveged服务状态的函数
check_haveged_status() {
    # 检查haveged服务是否处于活动状态
    local status=$(systemctl is-active haveged)
    if [ "$status" == "active" ]; then
        echo "检测成功: haveged服务正在运行。"
        return 0
    else
        echo "检测失败: haveged服务未启动或处于非活动状态。"
        return 1
    fi
}

# 主逻辑
main() {
     
    # 调用检查haveged状态的函数
    if check_haveged_status; then
        exit 0  # 检查成功，服务正在运行
    else
        exit 1  # 检查未通过，服务未启动或非活动状态
    fi
}

main "$@"


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
# Description: Security Baseline Check Script for 2.5.1
#
# #######################################################################################

# 函数：检查IMA是否启用和配置是否正确
check_ima() {
    # 检查内核启动参数中是否包含 'integrity=1'
    if ! grep -q 'integrity=1' /proc/cmdline; then
        echo "检测失败: 系统未启用IMA度量功能"
        return 1
    fi

    # 检查度量记录数是否大于1
    if [ "$(cat /sys/kernel/security/ima/runtime_measurements_count)" -le 1 ]; then
        echo "检测失败: IMA度量策略未正确配置或未生效"
        return 1
    fi

    return 0
}

# 主逻辑
main() {
    
    # 调用检查函数
    if check_ima; then
        echo "检查成功: IMA度量功能启用且配置正确"
        exit 0
    else
        exit 1
    fi
}

main "$@"


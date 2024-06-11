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
# Description: Security Baseline Check Script for 2.4.4
#
# #######################################################################################

# 函数：检查su受限使用
check_su_restriction() {
    local pamFile="/etc/pam.d/su"
    local expectedSetting="auth\s+required\s+pam_wheel.so\s+use_uid"

    # 检查pam_wheel.so模块的配置
    if grep -Eq "$expectedSetting" "$pamFile"; then
        echo "检查成功:su使用受到正确限制。"
        return 0
    else
        echo "检查失败:su使用未受到正确限制。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_su_restriction; then
    exit 0
else
    exit 1
fi


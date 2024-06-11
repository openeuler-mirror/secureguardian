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
# Description: Security Baseline Check Script for 2.2.8
#
# #######################################################################################

# 函数：检查是否禁止空口令登录
check_permit_empty_passwords() {
    local sshd_config="/etc/ssh/sshd_config"

    if [ ! -f "$sshd_config" ]; then
        echo "检测失败：未找到 $sshd_config 文件。"
        return 1
    fi

    # 检查PermitEmptyPasswords设置
    if grep -Eq "^\s*PermitEmptyPasswords\s+no" "$sshd_config"; then
        echo "检测通过：已正确配置禁止空口令登录。"
    else
        echo "检测失败：未配置禁止空口令登录或配置不正确。"
        return 1
    fi
}

# 主函数
main() {
    check_permit_empty_passwords
    local result=$?
    if [ $result -ne 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"


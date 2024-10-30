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
# Description: Security Baseline Fix Script for 2.2.1
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本检查并修复 PAM 配置，禁用历史口令重用功能。

# 检查 PAM 配置文件
system_auth="/etc/pam.d/system-auth"
password_auth="/etc/pam.d/password-auth"

# 自测功能
self_test() {
    echo "自测功能: 检查 pam_pwhistory.so 配置..."
    if grep -q "pam_pwhistory.so" "$system_auth" && grep -q "remember=5" "$system_auth"; then
        echo "系统认证配置通过自测。"
    else
        echo "系统认证配置自测失败，请检查配置。"
        exit 1
    fi
}

# 检查历史口令设置
check_history_passwords() {
    echo "检查 /etc/pam.d/system-auth 中的配置..."
    if grep -q "pam_pwhistory.so" "$system_auth"; then
        remember_value=$(grep "pam_pwhistory.so" "$system_auth" | grep -oP "remember=\K\d+")
        if [[ "$remember_value" -lt 5 ]]; then
            echo "发现历史口令次数设置为 $remember_value，低于最低要求 5，准备修复..."
            return 1
        fi
    else
        echo "未找到 pam_pwhistory.so 配置，准备添加..."
        return 2
    fi

    echo "检查 /etc/pam.d/password-auth 中的配置..."
    if grep -q "pam_pwhistory.so" "$password_auth"; then
        remember_value=$(grep "pam_pwhistory.so" "$password_auth" | grep -oP "remember=\K\d+")
        if [[ "$remember_value" -lt 5 ]]; then
            echo "发现历史口令次数设置为 $remember_value，低于最低要求 5，准备修复..."
            return 1
        fi
    else
        echo "未找到 pam_pwhistory.so 配置，准备添加..."
        return 2
    fi

    echo "历史口令设置检查通过。"
    return 0
}

# 修复历史口令设置
fix_history_passwords() {
    for auth_file in "$system_auth" "$password_auth"; do
        echo "修复 $auth_file ..."
        if ! grep -q "pam_pwhistory.so" "$auth_file"; then
            # 在 pam_deny.so 之前添加配置
            sed -i "/pam_deny.so/i password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root" "$auth_file"
            echo "已添加 pam_pwhistory.so 配置到 $auth_file."
        else
            echo "$auth_file 中已存在 pam_pwhistory.so 配置。"
        fi
    done
}

# 主逻辑
if [[ "$1" == "--self-test" ]]; then
    self_test
else
    check_history_passwords
    if [[ $? -ne 0 ]]; then
        fix_history_passwords
    fi
fi


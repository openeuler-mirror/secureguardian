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
#!/bin/bash

# 功能说明:
# 本脚本用于确保 su 命令仅限于 wheel 组用户使用，提升系统账号安全性。
# 如果未正确配置限制，将自动修复，以确保只有 wheel 组用户可以使用 su 命令。
# 支持 --self-test 选项以在测试环境中验证功能。

# PAM su 配置文件
pam_file="/etc/pam.d/su"
expected_setting="auth       required     pam_wheel.so use_uid"

# 备份 PAM 配置文件
backup_pam_file() {
    cp "$pam_file" "${pam_file}.bak.$(date +%F_%T)"
    echo "已备份 $pam_file 至 ${pam_file}.bak.$(date +%F_%T)"
}

# 应用 su 限制设置
apply_su_restriction() {
    backup_pam_file

    # 检查是否已存在未被注释的 pam_wheel.so 配置
    if grep -Eq "^[^#]*auth\s+required\s+pam_wheel.so\s+use_uid" "$pam_file"; then
        echo "已存在 su 命令的访问限制配置，无需修改。"
        return 0
    fi

    # 如果存在被注释的 pam_wheel.so 配置，解开注释
    if grep -Eq "^\s*#\s*auth\s+required\s+pam_wheel.so\s+use_uid" "$pam_file"; then
        sed -i 's/^\s*#\s*\(auth\s\+required\s\+pam_wheel.so\s\+use_uid\)/\1/' "$pam_file"
        echo "已解除被注释的 su 使用限制配置。"
        return 0
    fi

    # 在适当的位置插入配置
    # 查找 "auth include system-auth" 或 "auth substack system-auth" 之前的插入位置
    line_number=$(grep -n -E "^auth\s+(include|substack)\s+system-auth" "$pam_file" | cut -d: -f1 | head -n 1)
    if [[ -n "$line_number" ]]; then
        sed -i "${line_number}i\\$expected_setting" "$pam_file"
        echo "已在第 $line_number 行前插入 su 使用限制配置。"
    else
        echo "未找到 'auth include system-auth' 或 'auth substack system-auth' 行，将在文件末尾添加配置。"
        echo "$expected_setting" >> "$pam_file"
    fi
}

# 自测功能，模拟 PAM 配置修改
self_test() {
    echo "自测: 模拟配置 su 使用限制并验证。"
    local test_file="/tmp/su_pam_test"

    # 创建临时测试文件
    cp "$pam_file" "$test_file"

    # 临时设置 pam_file 为测试文件
    pam_file="$test_file"
    apply_su_restriction

    # 检查设置是否正确
    if grep -Eq "^[^#]*auth\s+required\s+pam_wheel.so\s+use_uid" "$test_file"; then
        echo "自测成功：su 使用限制配置正确。"
        rm "$test_file"
        return 0
    else
        echo "自测失败：su 使用限制配置未正确应用。"
        rm "$test_file"
        return 1
    fi
}

# 检查参数是否为 --self-test
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
fi

# 检查当前配置并执行修复
if grep -Eq "^[^#]*auth\s+required\s+pam_wheel.so\s+use_uid" "$pam_file"; then
    echo "su 使用限制已正确配置，无需更改。"
else
    echo "su 使用限制未配置，将进行修复。"
    apply_su_restriction
fi

# 返回成功状态
exit 0


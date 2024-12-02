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
# Description: Security Baseline fix Script for 2.4.9
#
# #######################################################################################

# 修复PAM配置，确保包含 pam_access.so 模块
fix_pam_configuration() {
    local files=("$@")  # 接收文件列表作为参数
    local pam_required_module="pam_access.so"

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            # 确保 pam_access.so 在 sufficient 控制行之前
            if ! grep -q "account.*required.*$pam_required_module" "$file"; then
                sed -i '0,/\(^\s*account\s\+required\s\+pam_unix.so\)/s//&\naccount     required      pam_access.so/' "$file"
                echo "已修复: 确保 $file 加载 pam_access.so 模块。"
            else
                echo "$file 已正确配置 pam_access.so，无需修复。"
            fi
        else
            echo "警告: $file 文件不存在，跳过修复。"
        fi
    done
}

# 修复 access.conf，限制 root 登录 tty1
fix_access_conf() {
    local file="$1"
    local access_conf_restriction="-:root:tty1"

    if [ ! -f "$file" ]; then
        echo "$file 文件不存在，创建并添加限制..."
        touch "$file"
    fi

    # 添加限制 root 用户登录 tty1
    if ! grep -qE "^\s*$access_conf_restriction" "$file"; then
        echo "$access_conf_restriction" >> "$file"
        echo "已修复: 限制 root 用户登录 tty1 的规则。"
    else
        echo "$file 已正确限制 root 用户登录 tty1，无需修复。"
    fi
}

# 自测功能
self_test() {
    echo "自测: 模拟失败场景并验证修复。"

    # 模拟 PAM 配置文件不含 pam_access.so 的情况
    local test_pam_file="/tmp/system-auth.test"
    echo "account     required      pam_unix.so" > "$test_pam_file"
    echo "account     sufficient    pam_localuser.so" >> "$test_pam_file"

    echo "模拟文件: $test_pam_file"
    
    # 调用修复函数
    fix_pam_configuration "$test_pam_file"

    # 检查文件是否正确修复，包含 pam_access.so 模块
    if grep -q "account.*required.*pam_access.so" "$test_pam_file"; then
        echo "自测成功: PAM 配置修复正确。"
    else
        echo "自测失败: PAM 配置未正确修复。"
        cat "$test_pam_file"  # 输出文件内容帮助调试
        rm -f "$test_pam_file"
        return 1
    fi

    # 模拟 access.conf 文件不含限制规则的情况
    local test_access_file="/tmp/access.conf.test"
    echo "# 模拟的 access.conf 文件" > "$test_access_file"

    echo "模拟文件: $test_access_file"
    
    # 调用修复函数
    fix_access_conf "$test_access_file"

    # 检查文件是否正确修复，包含 root:tty1 限制
    if grep -qE "^\s*-:root:tty1" "$test_access_file"; then
        echo "自测成功: access.conf 配置修复正确。"
        rm -f "$test_access_file"
        return 0
    else
        echo "自测失败: access.conf 配置未正确修复。"
        cat "$test_access_file"  # 输出文件内容帮助调试
        rm -f "$test_access_file"
        return 1
    fi
}

# 主函数
main() {
    if [[ "$1" == "--self-test" ]]; then
        self_test
        exit $?
    fi

    echo "修复 PAM 配置..."
    fix_pam_configuration "/etc/pam.d/system-auth" "/etc/pam.d/password-auth"

    echo "修复 /etc/security/access.conf 配置..."
    fix_access_conf "/etc/security/access.conf"

    echo "修复完成。"
    exit 0
}

# 执行主函数
main "$@"


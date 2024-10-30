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

# 功能说明:
# 本脚本用于检查并修复禁止空口令登录的配置。
# 支持指定例外账号，并提供自测功能确保修复逻辑的正确性。

# 备份原有配置文件
backup_file="/etc/ssh/sshd_config.bak.$(date +%F_%T)"
cp /etc/ssh/sshd_config "$backup_file"
echo "已备份 /etc/ssh/sshd_config 至 $backup_file"

# 默认例外账户
EXCEPTIONS=("root" "sync" "shutdown" "halt")

# 检查是否禁止空口令登录
check_permit_empty_passwords() {
    local sshd_config="/etc/ssh/sshd_config"

    if [ ! -f "$sshd_config" ]; then
        echo "检测失败：未找到 $sshd_config 文件。"
        return 1
    fi

    # 检查PermitEmptyPasswords设置
    if grep -Eq "^\s*PermitEmptyPasswords\s+no" "$sshd_config"; then
        echo "检测通过：已正确配置禁止空口令登录。"
        return 0
    else
        echo "检测失败：未配置禁止空口令登录或配置不正确。"
        return 1
    fi
}

# 修复空口令登录配置
fix_permit_empty_passwords() {
    local sshd_config="/etc/ssh/sshd_config"

    if ! grep -q "^\s*PermitEmptyPasswords\s+no" "$sshd_config"; then
        echo "修复: 在 $sshd_config 中添加禁止空口令登录配置。"
        echo "PermitEmptyPasswords no" >> "$sshd_config"
        echo "修复成功：已配置禁止空口令登录。"
    else
        echo "配置已存在，无需修复。"
    fi

    # 重启sshd服务
    systemctl restart sshd
    echo "sshd服务已重启。"
}

# 自测功能
self_test() {
    local test_config="/etc/ssh/sshd_config.test"

    # 创建测试配置文件并写入测试内容
    cp /etc/ssh/sshd_config "$test_config"
    echo "PermitEmptyPasswords yes" >> "$test_config"

    # 调用修复函数
    echo "开始自测修复空口令登录配置..."
    fix_permit_empty_passwords

    # 检查修复结果
    if grep -q "PermitEmptyPasswords no" "$test_config"; then
        echo "自测成功：禁止空口令登录的配置已修复。"
    else
        echo "自测失败：禁止空口令登录的配置未修复。"
    fi

    # 清理测试文件
    rm -f "$test_config"
}

# 主函数
main() {
    if [[ "$1" == "--self-test" ]]; then
        self_test
    else
        check_permit_empty_passwords
        local result=$?
        if [ $result -ne 0 ]; then
            echo "检测失败，准备进行修复..."
            fix_permit_empty_passwords
        fi
    fi
}

main "$@"


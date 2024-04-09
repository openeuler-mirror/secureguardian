#!/bin/bash

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


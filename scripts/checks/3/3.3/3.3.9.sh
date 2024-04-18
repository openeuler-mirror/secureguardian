#!/bin/bash

# 定义函数以检查 SSH 的 PermitRootLogin 配置
function check_permit_root_login() {
    local sshd_config="/etc/ssh/sshd_config"
    local actual_setting
    local error_msg=""

    # 使用 sshd -T 来获取实际运行时的配置
    actual_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')")
    if ! [[ "$actual_setting" =~ "permitrootlogin no" ]]; then
        error_msg+="检测失败: PermitRootLogin 未设置为 'no'。当前配置允许root登录。\n"
    fi

    # 检查 sshd_config 文件中是否显式配置了 PermitRootLogin 为 yes
    if grep -Eiq '^\s*PermitRootLogin\s+yes\b' "$sshd_config"; then
        error_msg+="检查失败:配置文件中 PermitRootLogin 设置为 yes。"
    fi

    if [ ! -z "$error_msg" ]; then
        echo -e "$error_msg"
        return 1
    fi
    return 0
}

# 调用函数并处理返回值
if check_permit_root_login; then
    echo "检查通过，root 用户通过 SSH 登录已禁用。"
    exit 0  # 检查通过，脚本成功退出
else
    echo "检查未通过，存在配置错误。"
    exit 1  # 检查未通过，脚本以失败退出
fi


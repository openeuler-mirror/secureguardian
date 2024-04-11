#!/bin/bash

# 函数：检查PAM配置以限制root本地登录
check_pam_configuration() {
    local files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
    local pam_required_module="pam_access.so"
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "检测失败: $file 文件不存在。"
            return 1
        fi
        
        # 查找pam_access.so模块和第一个account sufficient控制行的行号
        local pam_access_line=$(grep -nE "^\s*account\s+required\s+$pam_required_module" "$file" | cut -d: -f1 | head -n 1)
        local first_sufficient_line=$(grep -nE "^\s*account\s+sufficient" "$file" | cut -d: -f1 | head -n 1)
        
        if [[ -z "$pam_access_line" ]]; then
            echo "检测失败: $file 中未找到 $pam_required_module 模块。"
            return 1
        fi
        
        if [[ -n "$first_sufficient_line" && "$pam_access_line" -gt "$first_sufficient_line" ]]; then
            echo "检测失败: $file 中 $pam_required_module 模块在第一个sufficient控制行之后加载。"
            return 1
        fi
    done
    
    echo "检测成功: 所有检查的PAM配置文件均正确配置了 $pam_required_module 模块。"
    return 0
}

# 检查/etc/security/access.conf文件中root用户的限制
check_access_conf() {
    local access_conf="/etc/security/access.conf"
    local access_conf_restriction="-:root:tty1"

    if [ ! -f "$access_conf" ]; then
        echo "检测失败: $access_conf 文件不存在。"
        return 1
    fi

    if ! grep -qE "^\s*$access_conf_restriction" "$access_conf"; then
        echo "检测失败: $access_conf 文件未正确限制root用户登录tty1。"
        return 1
    fi

    return 0
}

# 执行检查函数
if check_pam_configuration && check_access_conf; then
    exit 0
else
    exit 1
fi


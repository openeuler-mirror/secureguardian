#!/bin/bash

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


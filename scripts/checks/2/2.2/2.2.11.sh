#!/bin/bash

# 函数：检查所有用户首次登录时是否强制修改口令
check_force_passwd_change() {
    local shadow_file="/etc/shadow"
    local passwd_file="/etc/passwd"
    local failed=0

    # 逐行读取/etc/passwd文件
    while IFS=':' read -r username _ _ _ _ _ shell; do
        # 检查用户是否应该被排除
        if [[ "$username" == "root" || "$username" == "sync" || "$username" == "halt" || "$username" == "shutdown" ]]; then
            continue
        fi
        # 检查是否是nologin或false用户
        if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false"  || "$shell" == "/usr/sbin/nologin" ]]; then
            continue
        fi
        
	 # 使用last命令检测用户是否登录过
        if last -w "$username" | grep -q "$username"; then
	    continue    			    
	fi
        # 检查该用户在/etc/shadow中的last_changed字段
        last_changed=$(grep "^$username:" "$shadow_file" | cut -d: -f3)
        # 如果last_changed字段不存在或者不为0，说明用户不是首次登录或未被设置首次登录时修改密码
        if [ -z "$last_changed" ] || [ "$last_changed" != "0" ]; then
            echo "账号 $username 未设置首次登录时强制修改口令。"
            failed=1
        fi
    done < "$passwd_file"

    return $failed
}

# 主函数
main() {
    check_force_passwd_change
    if [ $? -ne 0 ]; then
        echo "检测未通过: 存在未设置首次登录时强制修改口令的账号。"
        exit 1
    else
        echo "检测通过: 所有账号均已设置首次登录时强制修改口令。"
        exit 0
    fi
}

main


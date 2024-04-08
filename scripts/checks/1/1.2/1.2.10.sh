#!/bin/bash

# 检查是否安装了openldap-servers软件
check_ldap_installed() {
    if rpm -qa | grep -q "openldap-servers"; then
        echo "检查不通过,openldap-servers软件已安装。"
        return 1
    else
        echo "检查通过,openldap-servers软件未安装，符合规范要求。"
        return 0
    fi
}

# 执行检查
check_ldap_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


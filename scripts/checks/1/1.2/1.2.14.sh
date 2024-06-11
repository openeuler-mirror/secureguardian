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
# Description: Security Baseline Check Script for 1.2.14
#
# #######################################################################################

# 检查是否安装了openldap-clients软件
check_openldap_clients_installed() {
    if rpm -qa | grep -q "openldap-clients"; then
        echo "LDAP客户端软件openldap-clients已安装，不符合安全规范。"
        return 1 # 表示检测不通过
    else
        echo "LDAP客户端软件openldap-clients未安装，符合安全规范。"
        return 0 # 表示检测通过
    fi
}

# 执行检查
check_openldap_clients_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


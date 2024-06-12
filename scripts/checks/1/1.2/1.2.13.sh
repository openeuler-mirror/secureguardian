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
# Description: Security Baseline Check Script for 1.2.13
#
# #######################################################################################

# 检查是否安装了ypbind软件
check_ypbind_installed() {
    if rpm -qa | grep -q "ypbind"; then
        echo "NIS客户端软件ypbind已安装。"
        return 1
    else
        echo "NIS客户端软件ypbind未安装，符合规范要求。"
        return 0
    fi
}

# 执行检查
check_ypbind_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


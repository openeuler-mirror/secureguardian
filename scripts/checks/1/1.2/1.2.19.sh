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
# Description: Security Baseline Check Script for 1.2.19
#
# #######################################################################################

# 定义检测httpd软件是否已安装的函数
check_httpd_installed() {
    # 使用rpm命令检查httpd软件包是否已安装
    if rpm -q httpd &>/dev/null; then
        echo "检测不通过。HTTP服务(httpd)已安装。"
        return 1  # httpd包已安装，不符合要求，返回1
    else
        echo "检测通过。HTTP服务(httpd)未安装。"
        return 0  # httpd包未安装，符合要求，返回0
    fi
}

# 调用检测函数
check_httpd_installed

# 捕获函数返回值，并以此值退出脚本
exit $?


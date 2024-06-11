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
# Description: Security Baseline Check Script for 1.2.9
#
# #######################################################################################

# 检查avahi主服务软件是否安装
check_avahi_installed() {
    # 使用rpm命令检查是否安装了名为 "avahi" 的包
    if rpm -qa --qf "%{NAME}\n" | grep -x "avahi" > /dev/null; then
        echo "检测失败: avahi主服务软件已安装，不符合安全规范。"
        return 1
    else
        echo "检测成功:avahi主服务软件未安装，符合安全规范。"
        return 0
    fi
}

# 执行检查
check_avahi_installed; 

#以此值退出脚本
exit $?


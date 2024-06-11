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
# Description: Security Baseline Check Script for 1.2.18
#
# #######################################################################################

#!/bin/bash

# 检测X Window系统的组件是否已安装
check_x_window_installed() {
    # 使用rpm命令查找所有与X Window系统相关的包，但不直接输出结果
    if rpm -qa | grep -E "xorg-x11" &>/dev/null; then
        echo "检测不通过。已安装X Window系统的组件。"
        return 1
    else
        echo "检测通过。X Window系统的组件未安装。"
        return 0
    fi
}

# 执行检查
check_x_window_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval

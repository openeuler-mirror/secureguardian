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
# Description: Security Baseline Check Script for 1.2.1
#
# #######################################################################################

# 定义检测函数
check_ftp_installed() {
  if rpm -q ftp &>/dev/null; then
    return 1  # 假设找到了ftp包，不符合要求，返回1
  else
    return 0  # 没找到ftp包，符合要求，返回0
  fi
}

# 调用检测函数
check_ftp_installed

# 捕获函数返回值
retval=$?

if [ $retval -eq 0 ]; then
    echo "检测通过。"
else
    echo "检测不通过。"
fi

# 以此值退出脚本
exit $retval


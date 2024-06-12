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
# Description: Security Baseline Check Script for 1.2.23
#
# #######################################################################################

# 定义检测函数
check_rpcbind_enabled() {
  # 检查rpcbind服务是否启用
  if systemctl is-enabled rpcbind &>/dev/null; then
    echo "检测不通过。rpcbind服务已启用。"
    return 1
  else
    echo "检测通过。rpcbind服务未启用。"
    return 0
  fi
}

# 调用检测函数
check_rpcbind_enabled

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


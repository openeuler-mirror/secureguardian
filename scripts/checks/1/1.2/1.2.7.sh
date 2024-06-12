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
# Description: Security Baseline Check Script for 1.2.7
#
# #######################################################################################

# 检测debug-shell服务是否启用
check_debug_shell_enabled() {
  if systemctl is-enabled debug-shell | grep -q "disabled"; then
    echo "检测通过。debug-shell服务已禁用。"
    return 0
  else
    echo "检测不通过。debug-shell服务未禁用。"
    return 1
  fi
}

check_debug_shell_enabled
exit $?


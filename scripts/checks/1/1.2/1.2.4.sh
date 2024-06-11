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
# Description: Security Baseline Check Script for 1.2.4
#
# #######################################################################################

# 检测是否安装了不安全的SNMP协议版本
check_snmp_installed() {
  if rpm -qa | grep -qE "net-snmp-[0-9]"; then
    echo "检测不通过。SNMP版本已安装。"
    return 1
  else
    echo "检测通过。SNMP版本未安装。"
    return 0
  fi
}

check_snmp_installed
exit $?


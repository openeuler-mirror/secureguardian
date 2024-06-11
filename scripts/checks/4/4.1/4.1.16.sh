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
# Description: Security Baseline Check Script for 4.1.16
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查是否正确配置了SELinux相关的审计规则。
# 包括对SELinux配置文件和策略文件的监控。

function check_audit_rules {
  local missing_rules=0
  local paths=("/etc/selinux" "/usr/share/selinux")

  for path in "${paths[@]}"; do
    if ! auditctl -l | grep -qi "$path"; then
      echo "检测失败: $path 目录未配置审计规则。"
      missing_rules=1
    fi
  done

  if [ $missing_rules -ne 0 ]; then
    return 1
  fi

  echo "检查成功:所有审计规则检查通过。"
  return 0
}

# 调用检查函数
check_audit_rules
exit_code=$?
exit $exit_code


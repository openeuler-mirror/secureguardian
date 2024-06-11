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
# Description: Security Baseline Check Script for 4.1.13
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查是否已配置对 /etc/sudoers 和 /etc/sudoers.d/ 目录的审计规则。
# 通过简单检查是否存在针对这些关键配置文件的监控，本脚本有助于保障系统安全。

# 检查审计规则函数
function check_audit_rules {
  # 检查 /etc/sudoers 文件的审计规则
  if ! auditctl -l | grep -q "/etc/sudoers "; then
    echo "检测失败: 未对 /etc/sudoers 文件配置审计规则。"
    return 1
  fi

  # 检查 /etc/sudoers.d/ 目录的审计规则
  if ! auditctl -l | grep -q "/etc/sudoers.d "; then
    echo "检测失败: 未对 /etc/sudoers.d 目录配置审计规则。"
    return 1
  fi

  echo "检查成功:sudo相关审计规则检查通过。"
  return 0
}

# 调用检查函数并处理返回值
if check_audit_rules; then
  exit 0
else
  exit 1
fi


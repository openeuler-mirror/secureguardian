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
# Description: Security Baseline Check Script for 1.1.13
#
# #######################################################################################

# 检测系统中是否存在不必要的SUID/SGID位设置
check_unnecessary_suid_sgid() {
  # 排除 /proc, /sys 和 /dev 目录，避免访问动态生成的文件系统内容
  # 使用 -print 选项直接打印出匹配的文件路径
  local files=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type f \( -perm -4000 -o -perm -2000 \) -print | head -n 1)
  
  if [ ! -z "$files" ]; then
    echo "系统中存在不必要的SUID/SGID位设置的文件："
    echo "$files"
    return 1  # 检测未通过
  else
    echo "系统中不存在不必要的SUID/SGID位设置。"
    return 0  # 检测通过
  fi
}

# 调用检测函数
if check_unnecessary_suid_sgid; then
  exit 0  # 检测通过，正常退出
else
  exit 1  # 检测未通过，错误退出
fi


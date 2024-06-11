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
# Description: Security Baseline Check Script for 1.1.6
#
# #######################################################################################

# 检测系统中是否存在全局可写文件
check_global_writable_files() {
  local file_found=$(find / -type f -perm -0002 ! -path "/proc/*" ! -path "/sys/*" -print -quit)
  if [ ! -z "$file_found" ]; then
    echo "发现全局可写文件: $file_found"
    exit 1
  else
    echo "未发现全局可写文件。"
    exit 0
  fi
}

# 调用检测函数
check_global_writable_files


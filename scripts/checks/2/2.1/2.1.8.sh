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
# Description: Security Baseline Check Script for 2.1.8
#
# #######################################################################################

# 检查/etc/passwd中UID的唯一性
check_unique_uid() {
  # 使用awk检查UID是否唯一
  local duplicate_uids=$(awk -F':' '{print $3}' /etc/passwd | sort | uniq -d)

  if [ -n "$duplicate_uids" ]; then
    echo "检测失败: 发现重复的UID"
    echo "$duplicate_uids"
    return 1
  else
    echo "检测成功: 所有UID均唯一"
    return 0
  fi
}

# 调用函数并处理返回值
if check_unique_uid; then
  exit 0
else
  exit 1
fi


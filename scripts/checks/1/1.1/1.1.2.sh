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
# Description: Security Baseline Check Script for 1.1.2
#
# #######################################################################################

# 定义检查空链接文件的函数
check_empty_links() {
  # 使用 find 命令查找并排除特定目录
  local empty_link=$(find / -path /var -prune -o -path /run -prune -o -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type l ! -exec test -e {} \; -print | head -n 1)

  if [[ ! -z $empty_link ]]; then
    echo "找到空链接文件：$empty_link"
    return 1  # 发现问题，返回false
  else
    echo "未找到空链接文件。"
    return 0  # 未发现问题，返回true
  fi
}

# 调用函数并处理返回值
if check_empty_links; then
  #echo "检查通过，不存在空链接文件。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过，存在空链接文件。"
  exit 1  # 检查未通过，脚本以失败退出
fi


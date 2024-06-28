#!/bin/bash

# #######################################################################################
#
# Copyright (c) SecureGuardian.
# All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline fix Script for 1.1.4
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查并修复系统中全局可写目录未设置粘滞位的问题。全局可写目录需设置粘滞位以防止未授权用户删除不属于他们的文件。

# 定义检查并修复全局可写目录未设置粘滞位的函数
fix_global_writable_directories() {
  local dirs_with_issues=$(find / -type d -perm -0002 -a ! -perm -1000 -print)

  if [[ ! -z $dirs_with_issues ]]; then
    echo "检测到全局可写目录未设置粘滞位，正在进行修复:"
    while IFS= read -r dir; do
      echo "处理目录: $dir"
      chmod 1777 "$dir"
      echo "已设置粘滞位: $dir"
    done <<< "$dirs_with_issues"
    return 1  # 存在问题，返回false
  else
    echo "所有全局可写目录已正确设置粘滞位。"
    return 0  # 未发现问题，返回true
  fi
}

# 自测部分
self_test() {
  # 创建测试环境
  mkdir -p /tmp/test_global_writable
  chmod 0777 /tmp/test_global_writable

  echo "自测: 创建了全局可写目录 /tmp/test_global_writable"
  ls -ld /tmp/test_global_writable

  # 运行修复函数
  fix_global_writable_directories

  # 验证修复
  echo "验证修复:"
  ls -ld /tmp/test_global_writable

  # 清理测试环境
  rm -rf /tmp/test_global_writable
}

# 主执行逻辑
if [[ "$1" == "/?" ]]; then
  echo "用法：./script.sh [--self-test]"
  echo "  --self-test     进行脚本自检"
  exit 0
elif [[ "$1" == "--self-test" ]]; then
  self_test
else
  fix_global_writable_directories
fi

exit $?


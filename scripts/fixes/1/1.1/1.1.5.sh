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
# Description: Security Baseline fix Script for 1.1.5
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查并修复系统中UMASK设置。目标是确保UMASK设置为0077，以强化文件和目录的安全性。

# 定义检查并修复UMASK设置的函数
fix_umask_settings() {
  local target_value="077"
  local files_to_check=("/etc/bashrc" "/etc/profile" "$HOME/.bashrc")

  for file in "${files_to_check[@]}"; do
    # 检查文件是否存在 umask 设置，忽略注释行
    if grep -qE "^[[:space:]]*umask[[:space:]]+[0-9]+" "$file"; then
      # 替换已存在的 umask 设置，确保它不在注释行
      sed -i -r "/^[^#]*umask[[:space:]]+/c\umask $target_value" "$file"
      echo "已更新 $file 中的 UMASK 设置为 $target_value。"
    else
      # 如果文件中不存在 umask 设置，添加到文件末尾
      echo "umask $target_value" >> "$file"
      echo "已在 $file 中添加 UMASK 设置 $target_value。"
    fi
  done
}

# 自测部分
self_test() {
  # 创建测试文件和目录，检查权限
  touch testfile
  mkdir testdir

  fix_umask_settings

  echo "自测结果:"
  ls -ld testfile testdir

  # 清理测试文件和目录
  rm -f testfile
  rm -rf testdir
}

# 主执行逻辑
if [[ "$1" == "/?" ]]; then
  echo "用法：./script.sh [--self-test]"
  echo "  --self-test     进行脚本自检"
  exit 0
elif [[ "$1" == "--self-test" ]]; then
  self_test
else
  fix_umask_settings
fi

exit $?


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
# Description: Security Baseline fix Script for 1.1.3
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查并修复系统中存在的可执行的隐藏文件。这些文件可能会导致安全风险。

# 定义检查并修复可执行的隐藏文件的函数
fix_executable_hidden_files() {
  # 构建find命令
  local hidden_exec_files=$(find / -type f -name ".*"  -perm /+x -print)

  if [[ ! -z $hidden_exec_files ]]; then
    echo "检测到可执行的隐藏文件:"
    echo "$hidden_exec_files"
    while IFS= read -r file; do
      echo "正在处理文件: $file"
      chmod 644 "$file"
      echo "已去除可执行权限: $file"
    done <<< "$hidden_exec_files"
    return 1  # 存在问题，返回false
  else
    echo "未检测到可执行的隐藏文件。"
    return 0  # 未发现问题，返回true
  fi
}

# 自测部分
self_test() {
  # 创建测试环境
  mkdir -p /tmp/testdir
  touch /tmp/testdir/.hidden_exec
  chmod +x /tmp/testdir/.hidden_exec

  echo "自测: 创建了可执行的隐藏文件 /tmp/testdir/.hidden_exec"
  ls -l /tmp/testdir/.hidden_exec

  # 运行修复函数
  fix_executable_hidden_files

  # 清理测试环境
  rm -rf /tmp/testdir
}

# 主执行逻辑
if [[ "$1" == "/?" ]]; then
  echo "用法：./script.sh [--self-test]"
  echo "  --self-test     进行脚本自检"
  exit 0
elif [[ "$1" == "--self-test" ]]; then
  self_test
else
  fix_executable_hidden_files
fi

exit $?


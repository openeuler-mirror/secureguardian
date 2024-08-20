#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Fix Script for Removing Debugging Tools using Template
#
# #######################################################################################

# 功能说明:
# 本脚本用于调用模板脚本，卸载调测类工具（如strace、gdb、perf等），确保系统符合安全基线要求。

# 获取当前脚本所在的目录
SCRIPT_DIR=$(dirname "$0")

# 模板脚本的相对路径
TEMPLATE_SCRIPT="$SCRIPT_DIR/rpm_fix_template.sh"

# 调测类工具列表
tools=("strace" "gdb" "perf" "binutils-extra" "appict" "kmem_analyzer_tools")

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
  echo "软件类暂无实现自测程序"
  exit 0
fi

# 遍历工具列表并调用模板脚本卸载每个工具
for tool in "${tools[@]}"; do
  bash "$TEMPLATE_SCRIPT" "$tool"

  # 检查修复结果
  if [[ $? -ne 0 ]]; then
    echo "卸载 $tool 失败"
    exit 1
  fi
done

exit 0


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
# Description: Security Baseline Fix Script for Removing HTTP Services using Template
#
# #######################################################################################

# 功能说明:
# 本脚本用于调用模板脚本，卸载HTTP服务，确保系统符合安全基线建议。

# 获取当前脚本所在的目录
SCRIPT_DIR=$(dirname "$0")

# 模板脚本的相对路径
TEMPLATE_SCRIPT="$SCRIPT_DIR/rpm_fix_template.sh"

# HTTP服务组件列表
components=("httpd")

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
  echo "软件类暂无实现自测程序"
  exit 0
fi

# 遍历组件列表并调用模板脚本卸载每个组件
for component in "${components[@]}"; do
  bash "$TEMPLATE_SCRIPT" "$component"

  # 检查修复结果
  if [[ $? -ne 0 ]]; then
    echo "卸载 $component 失败"
    exit 1
  fi
done

exit 0


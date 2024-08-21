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
# Description: Security Baseline Fix Script for Disabling DNS Services using Template
#
# #######################################################################################

# 功能说明:
# 本脚本用于调用模板脚本，禁用DNS服务，确保系统符合安全基线要求。

# 获取当前脚本所在的目录
SCRIPT_DIR=$(dirname "$0")

# 模板脚本的相对路径
TEMPLATE_SCRIPT="$SCRIPT_DIR/service_fix_template.sh"

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
  echo "软件类暂无实现自测程序"
  exit 0
fi

# 调用模板脚本禁用named服务
bash "$TEMPLATE_SCRIPT" "named"

# 检查修复结果
if [[ $? -eq 0 ]]; then
  exit 0
else
  exit 1
fi


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
# Description: Security Baseline Check Script for 4.1.21
#
# #######################################################################################

# 功能说明:
# 此脚本用于检查是否已经配置了文件系统挂载的审计规则。
# 它将检查 mount 系统调用是否被正确监控，并确保符合安全审计要求。

# 默认系统架构为64位
ARCH="b64"

# 显示帮助信息
function show_usage() {
  echo "Usage: $0 [-a arch] [-h]"
  echo "Options:"
  echo "  -a, --arch 指定系统架构类型 ('b32' 或 'b64'), 默认为 'b64'"
  echo "  -h, --help 显示帮助信息"
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -a|--arch)
      ARCH="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Error: Unsupported flag $1" >&2
      show_usage
      exit 1
      ;;
  esac
done

# 定义系统调用列表
syscall_errors=("mount")
missing_rules=0
warnings=0

# 检查文件系统挂载操作的审计规则
for syscall in "${syscall_errors[@]}"; do
  # 搜索是否存在任何与mount相关的审计规则
  if ! auditctl -l | grep -qiE "arch=$ARCH .*-S.*$syscall"; then
    echo "检测失败: 在$ARCH架构下，系统调用 $syscall 相关的审计规则未配置。"
    missing_rules=1
  fi
done

# 汇总结果
if [ "$missing_rules" -eq 1 ]; then
  exit 1
else
  echo "检查成功:所有文件系统挂载相关的审计规则检查通过。"
  exit 0
fi


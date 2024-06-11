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
# Description: Security Baseline Check Script for 4.1.17
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查网络环境相关的审计规则是否正确配置，包括对系统调用和关键文件的监控。

function show_usage {
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  -a, --arch       指定架构类型，支持 'b32' 或 'b64'，默认为 'b64'"
  echo "  -h, --help       显示帮助信息"
  exit 1
}

ARCH="b64"  # 默认架构类型为64位

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a|--arch) ARCH="$2"; shift ;;
    -h|--help) show_usage ;;
    *) echo "未知参数: $1"; show_usage; exit 1 ;;
  esac
  shift
done

# 检查审计规则配置
function check_audit_rules {
  local arch=$1
  local syscalls=("sethostname" "setdomainname")
  local files=("/etc/hosts" "/etc/issue" "/etc/issue.net")
  local missing_rules=0

  # 检查系统调用审计规则
  for syscall in "${syscalls[@]}"; do
    if ! auditctl -l | grep -qiE "arch=$arch .*-S.*$syscall\b"; then
      echo "检测失败: 未配置 $arch 架构下 $syscall 的系统调用审计规则。"
      missing_rules=1
    fi
  done

  # 检查关键文件的审计规则
  for file in "${files[@]}"; do
    if ! auditctl -l | grep -qi "$file"; then
      echo "检测失败: 文件 $file 的审计规则未配置。"
      missing_rules=1
    fi
  done

  if [ $missing_rules -ne 0 ]; then
    return 1
  else
    echo "检查成功:所有网络环境相关的审计规则检查通过。"
    return 0
  fi
}

# 调用检查函数
check_audit_rules $ARCH
exit_code=$?
exit $exit_code


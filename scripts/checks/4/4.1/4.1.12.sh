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
# Description: Security Baseline Check Script for 4.1.12
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查 auditd 配置文件中关于磁盘空间阈值的配置。
# 它确保了磁盘空间相关的配置项被正确设置，并允许用户通过参数自定义阈值检查。
# 这有助于确保auditd配置得当，防止在磁盘空间不足时影响系统正常运行。

function show_usage {
  echo "用法: $0 [-c <配置文件路径>] [选项]"
  echo "  -c, --config <文件>                   指定auditd配置文件，默认为/etc/audit/auditd.conf"
  echo "  -s, --space-left <MB>                 检查space_left阈值是否至少为指定的MB"
  echo "  -sa, --space-left-action <动作>       检查space_left_action的设置"
  echo "  -a, --admin-space-left <MB>           检查admin_space_left阈值是否至少为指定的MB"
  echo "  -aa, --admin-space-left-action <动作> 检查admin_space_left_action的设置"
  echo "  -df, --disk-full-action <动作>        检查disk_full_action的设置"
  echo "  -de, --disk-error-action <动作>       检查disk_error_action的设置"
  echo "  -?, /?, --help                        显示帮助信息"
  exit 1
}

# 默认配置文件路径
CONFIG_FILE="/etc/audit/auditd.conf"

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -c|--config) CONFIG_FILE="$2"; shift ;;
    -s|--space-left) SPACE_LEFT="$2"; shift ;;
    -sa|--space-left-action) SPACE_LEFT_ACTION="$2"; shift ;;
    -a|--admin-space-left) ADMIN_SPACE_LEFT="$2"; shift ;;
    -aa|--admin-space-left-action) ADMIN_SPACE_LEFT_ACTION="$2"; shift ;;
    -df|--disk-full-action) DISK_FULL_ACTION="$2"; shift ;;
    -de|--disk-error-action) DISK_ERROR_ACTION="$2"; shift ;;
    -?|/?|--help) show_usage ;;
    *) echo "未知参数: $1"; show_usage ;;
  esac
  shift
done

# 检查配置项是否存在，并可选地检查其值
function check_config {
  local key=$1
  local expected_value=$2
  local value=$(grep -i "^$key\s*=" "$CONFIG_FILE" | awk -F '=' '{print $2}' | xargs)
  
  if [[ -z "$value" ]]; then
    echo "检测失败: $key 未在 $CONFIG_FILE 中配置。"
    return 1
  elif [[ -n "$expected_value" && "$value" != "$expected_value" ]]; then
    echo "检测失败: $key 配置值应为 $expected_value，实际配置为 $value。"
    return 1
  fi
}

# 调用检查函数
check_failures=0
check_config "space_left" "$SPACE_LEFT" || check_failures=1
check_config "space_left_action" "$SPACE_LEFT_ACTION" || check_failures=1
check_config "admin_space_left" "$ADMIN_SPACE_LEFT" || check_failures=1
check_config "admin_space_left_action" "$ADMIN_SPACE_LEFT_ACTION" || check_failures=1
check_config "disk_full_action" "$DISK_FULL_ACTION" || check_failures=1
check_config "disk_error_action" "$DISK_ERROR_ACTION" || check_failures=1

if [[ $check_failures -eq 0 ]]; then
  echo "检查成功:所有配置项检查通过。"
  exit 0
else
  exit 1
fi


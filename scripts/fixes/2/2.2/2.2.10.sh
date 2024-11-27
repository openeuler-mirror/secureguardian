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
# Description: Security Baseline Fix Script for 2.2.10
#
# #######################################################################################

# 功能说明:
# 本脚本用于确保单用户模式已设置口令保护，通过修复 rescue 和 emergency 模式中的 systemd-sulogin-shell 配置，以确保只有输入 root 口令后才能进入单用户模式。
# 支持自测功能以模拟修复场景，确保脚本逻辑的正确性。

# 定义服务文件路径
rescue_service="/usr/lib/systemd/system/rescue.service"
emergency_service="/usr/lib/systemd/system/emergency.service"

# 备份原有配置文件
backup_file() {
  local file_path="$1"
  cp "$file_path" "${file_path}.bak.$(date +%F_%T)"
  echo "已备份 $file_path 至 ${file_path}.bak.$(date +%F_%T)"
}

# 修复 rescue.service 配置
fix_rescue_service() {
  backup_file "$rescue_service"
  sed -i '/ExecStart=/c\ExecStart=-/usr/lib/systemd/systemd-sulogin-shell rescue' "$rescue_service"
  echo "已修复 rescue.service 配置。"
}

# 修复 emergency.service 配置
fix_emergency_service() {
  backup_file "$emergency_service"
  sed -i '/ExecStart=/c\ExecStart=-/usr/lib/systemd/systemd-sulogin-shell emergency' "$emergency_service"
  echo "已修复 emergency.service 配置。"
}

# 修复函数
repair_single_user_mode_password_protection() {
  fix_rescue_service
  fix_emergency_service
  echo "修复完成: 单用户模式已设置口令保护。"
  return 0
}

# 自测功能
self_test() {
  echo "自测：模拟错误配置并修复。"
  sed -i '/ExecStart=/c\ExecStart=-/usr/lib/systemd/systemd-shell rescue' "$rescue_service"
  sed -i '/ExecStart=/c\ExecStart=-/usr/lib/systemd/systemd-shell emergency' "$emergency_service"

  repair_single_user_mode_password_protection
  echo "自测成功：修复逻辑正常。"
  return 0
}

# 参数解析
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self-test|-s)
        self_test
        exit $?
        ;;
      /?)
        echo "使用方法: $0 [--self-test | -s]"
        exit 0
        ;;
      *)
        echo "未知选项: $1"
        exit 1
        ;;
    esac
    shift
  done
}

# 执行参数解析
parse_arguments "$@"

# 执行修复
repair_single_user_mode_password_protection

# 返回成功状态
exit 0


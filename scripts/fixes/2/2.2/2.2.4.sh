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
# Description: Security Baseline Fix Script for 2.2.4
#
# #######################################################################################
# 函数：修复口令中不包含账号字符串
fix_password_no_username() {
  local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local found_issues=0

  for pam_file in "${pam_files[@]}"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      continue
    fi

    # 确保没有 usercheck=0
    if grep -q "usercheck=0" "$pam_file"; then
      echo "修复: 移除 $pam_file 中的 usercheck=0 配置。"
      sed -i "/usercheck=0/d" "$pam_file"
      echo "修复成功: 移除了 $pam_file 中的 usercheck=0 配置。"
      found_issues=1
    fi
  done

  # 如果没有发现问题，输出无需修复的信息
  if [ "$found_issues" -eq 0 ]; then
    echo "所有配置文件均符合要求，无需修复。"
  fi
}

# 自测功能
self_test() {
  echo "自测模式: 检查口令中是否包含账号字符串的配置。"

  # 检查配置文件是否符合要求
  for pam_file in "/etc/pam.d/system-auth" "/etc/pam.d/password-auth"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      continue
    fi

    if grep -q "usercheck=0" "$pam_file"; then
      echo "自测失败: $pam_file 中存在不符合要求的 usercheck=0 配置。"
      return 1
    fi
  done

  echo "自测成功: 所有配置文件均符合要求。"
  return 0
}

# 参数解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    --self-test)
      self_test
      exit $?
      ;;
    *)
      echo "使用方法: $0 [--self-test]"
      exit 1
      ;;
  esac
done

# 执行修复
fix_password_no_username


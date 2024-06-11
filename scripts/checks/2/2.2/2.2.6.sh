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
# Description: Security Baseline Check Script for 2.2.6
#
# #######################################################################################

# 函数：检查弱口令字典设置是否正确
check_weak_password_dict() {
  # 默认检查的文件路径
  local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local pwquality_config="/etc/security/pwquality.conf"
  local dict_check_enabled=1  # 默认认为dict_check是启用的

  # 检查PAM配置文件
  for pam_file in "${pam_files[@]}"; do
    if [ -f "$pam_file" ]; then
      echo "正在检查 $pam_file ..."
      if grep -q "pam_pwquality.so" "$pam_file" && ! grep -q "dictcheck=0" "$pam_file"; then
        echo "$pam_file 配置了弱口令字典检查。"
      else
        echo "$pam_file 未配置弱口令字典检查或者已被禁用。"
        dict_check_enabled=0
      fi
    else
      echo "警告：$pam_file 文件不存在。"
      dict_check_enabled=0
    fi
  done

  # 检查pwquality配置
  if [ -f "$pwquality_config" ]; then
    echo "正在检查 $pwquality_config ..."
    if grep -q "^dictcheck=" "$pwquality_config" && grep -q "dictcheck=0" "$pwquality_config"; then
      echo "$pwquality_config 中弱口令字典检查被明确禁用。"
      dict_check_enabled=0
    else
      echo "$pwquality_config 未明确禁用弱口令字典检查。"
    fi
  else
    echo "警告：$pwquality_config 文件不存在。"
  fi

  # 根据检查结果决定脚本退出状态
  if [ "$dict_check_enabled" -eq 1 ]; then
    echo "弱口令字典检查配置正确。"
    return 0  # 检查通过
  else
    echo "存在配置不符合要求。"
    return 1  # 检查未通过
  fi
}

# 调用函数并处理返回值
if check_weak_password_dict; then
  exit 0  # 检查通过，脚本成功退出
else
  exit 1  # 存在配置不符合要求
fi


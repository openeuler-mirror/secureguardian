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
# Description: Security Baseline Check Script for 2.2.4
#
# #######################################################################################

# 函数：检查密码中是否禁止包含账号字符串
check_password_not_contain_username() {
  # 定义要检查的文件路径
  local check_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local issue_found=0

  # 遍历文件进行检查
  for file in "${check_files[@]}"; do
    if [ -f "$file" ]; then
      echo "正在检查文件：$file"
      # 检查文件中是否含有usercheck=0的配置
      if grep -P "pam_pwquality\.so" "$file" | grep -q "usercheck=0"; then
        echo "检测失败：$file 中包含 'usercheck=0'，这允许密码中包含账号字符串。"
        issue_found=1
      else
        echo "$file 中未找到 'usercheck=0' 配置，符合要求。"
      fi
    else
      echo "警告：未找到文件 $file，跳过检查。"
    fi
  done

  # 根据检查结果返回状态
  if [ "$issue_found" -eq 0 ]; then
    echo "所有检查的配置文件均符合要求。"
    return 0  # 检查通过
  else
    echo "存在配置不符合要求。"
    return 1  # 检查未通过
  fi
}

# 调用函数并处理返回值
if check_password_not_contain_username; then
  exit 0  # 检查通过，脚本成功退出
else
  exit 1  # 存在配置不符合要求
fi


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
# Description: Security Baseline Check Script for 2.3.1
#
# #######################################################################################

# 默认的连续登录失败次数和锁定时间（秒）
default_deny=3
default_unlock_time=300

# 通过命令行参数获取自定义值
while getopts ":d:u:" opt; do
  case ${opt} in
    d ) default_deny=$OPTARG ;;
    u ) default_unlock_time=$OPTARG ;;
    \? ) echo "用法: $0 [-d 连续失败次数] [-u 锁定时间（秒）]" ;;
  esac
done

# 检查 /etc/pam.d/system-auth 和 /etc/pam.d/password-auth 配置文件
check_lock_settings() {
  local fail_count=0
  local files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")

  for file in "${files[@]}"; do

    # 分别检查 deny 和 unlock_time 配置
    if grep -q "pam_faillock.so" "$file"; then
      if ! grep -q "deny=$default_deny" "$file"; then
        echo "错误：$file 中 deny 设置不符合要求（应为 $default_deny）。"
        ((fail_count++))
      fi
      if ! grep -q "unlock_time=$default_unlock_time" "$file"; then
        echo "错误：$file 中 unlock_time 设置不符合要求（应为 $default_unlock_time 秒）。"
        ((fail_count++))
      fi
    else
      echo "警告：$file 未找到 pam_faillock.so 配置。"
      ((fail_count++))
    fi
  done

  if [ $fail_count -eq 0 ]; then
    echo "检查成功:所有检查通过，pam_faillock 配置符合要求。"
    return 0
  else
    echo "检查失败:存在配置不符合要求，请检查。"
    return 1
  fi
}


# 调用函数并处理返回值
if check_lock_settings "$@"; then
  exit 0  #
else
  exit 1  # 检查未通过
fi

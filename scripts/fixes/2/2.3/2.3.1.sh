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

# 功能说明:
# 本脚本用于确保 PAM 配置文件中设置了登录失败后的锁定功能。
# 脚本支持自定义登录失败次数和锁定时间，默认分别为3次和300秒。
# 支持 --self-test 功能，模拟测试配置是否正确应用。

# 默认的连续登录失败次数和锁定时间（秒）
default_deny=3
default_unlock_time=300

# PAM 配置文件路径
files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")

# 解析命令行参数
while getopts ":d:u:-:" opt; do
  case ${opt} in
    d ) default_deny=$OPTARG ;;
    u ) default_unlock_time=$OPTARG ;;
    - )
      case "${OPTARG}" in
        self-test) self_test ;;
        *) echo "未知选项 --${OPTARG}" ;;
      esac ;;
    \? ) echo "用法: $0 [-d 连续失败次数] [-u 锁定时间（秒）] [--self-test]" ;;
  esac
done

# 备份配置文件
backup_file() {
  local file="$1"
  cp "$file" "${file}.bak.$(date +%F_%T)"
  echo "已备份 $file 至 ${file}.bak.$(date +%F_%T)"
}

# 修复配置文件中的 pam_faillock 设置，确保顺序正确
apply_lock_settings() {
  local file="$1"
  backup_file "$file"

  # 替换 preauth 条目
  sed -i '/auth.*pam_faillock.so.*preauth/ c\auth  required  pam_faillock.so preauth audit deny='"$default_deny"' even_deny_root unlock_time='"$default_unlock_time" "$file"

  # 替换 authfail 条目
  sed -i '/auth.*pam_faillock.so.*authfail/ c\auth  [default=die] pam_faillock.so authfail audit deny='"$default_deny"' even_deny_root unlock_time='"$default_unlock_time" "$file"

  # 替换 authsucc 条目
  sed -i '/auth.*pam_faillock.so.*authsucc/ c\auth  sufficient  pam_faillock.so authsucc audit deny='"$default_deny"' even_deny_root unlock_time='"$default_unlock_time" "$file"

  echo "$file 配置已更新：deny=$default_deny，unlock_time=$default_unlock_time 秒。"
}

# 自测功能
self_test() {
  echo "自测: 模拟修改配置文件并验证设置。"
  test_file="/tmp/system-auth-test"
  cp "${files[0]}" "$test_file"

  apply_lock_settings "$test_file"

  # 检查设置是否应用
  if grep -q "deny=$default_deny" "$test_file" && grep -q "unlock_time=$default_unlock_time" "$test_file"; then
    echo "自测成功：测试文件中已正确应用锁定设置。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：锁定设置未正确应用，请检查脚本。"
    rm "$test_file"
    return 1
  fi
}

# 为所有配置文件应用设置
for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    apply_lock_settings "$file"
  else
    echo "警告：未找到配置文件 $file，跳过。"
  fi
done

# 返回成功状态
exit 0


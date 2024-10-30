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
# Description: Security Baseline Fix Script for 2.2.3
#
# #######################################################################################

# 初始化参数
self_test_mode=false

# 参数解析函数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self-test)
        self_test_mode=true
        shift
        ;;
      *)
        echo "使用方法: $0 [--self-test]"
        exit 1
        ;;
    esac
  done
}

# 函数：修复用户修改自身口令时需验证旧口令
fix_password_change_policy() {
  local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local found_issues=0

  for pam_file in "${pam_files[@]}"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      continue
    fi

    # 检查并确保 pam_unix.so 行存在且不被注释
    if ! grep -q "^\s*password\s\+\(requisite\|sufficient\)\s\+pam_unix.so" "$pam_file"; then
      echo "修复: 在 $pam_file 中添加旧口令验证配置。"
      sed -i "/^password\s\+required\s\+pam_deny.so/i password    requisite     pam_unix.so" "$pam_file"
      echo "修复成功: 在 $pam_file 中添加旧口令验证配置。"
    else
      echo "$pam_file 中已配置旧口令验证，无需修复。"
    fi
  done
}

# 自测功能
self_test() {
  echo "自测模式: 创建用户 testuser 并验证旧口令功能。"

  # 检查并删除已有的测试用户
  if id testuser &>/dev/null; then
    userdel -r testuser
  fi

  # 创建测试用户
  useradd testuser
  echo "testuser:TestPassword123" | chpasswd

  # 尝试用旧口令修改口令
  echo "正在尝试用旧口令修改 testuser 的口令..."
  if echo -e "TestPassword123\nNewPassword123" | passwd testuser; then
    echo "自测失败: 用户能够在不验证旧口令的情况下修改口令。"
    userdel -r testuser
    return 1
  else
    echo "自测成功: 旧口令验证正常。"
    userdel -r testuser
    return 0
  fi
}

# 主执行逻辑
parse_arguments "$@"

if $self_test_mode; then
  self_test
else
  fix_password_change_policy
fi


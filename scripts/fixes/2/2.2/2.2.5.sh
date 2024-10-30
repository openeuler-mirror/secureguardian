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
# Description: Security Baseline Fix Script for 2.2.1
#
# #######################################################################################

# 函数：修复口令使用强Hash算法加密
fix_password_hash_algorithm() {
  local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local found_issues=0

  for pam_file in "${pam_files[@]}"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      continue
    fi

    # 检查并替换弱哈希算法
    if grep -q "pam_unix.so.*\(md5\|sha1\|sha256\)" "$pam_file"; then
      echo "修复: 将 $pam_file 中的弱哈希算法替换为SHA512。"
      sed -i -E "s/(password\s+\S+\s+pam_unix.so\s+)(md5|sha1|sha256)/\1sha512/g" "$pam_file"
      echo "修复成功: $pam_file 中的弱哈希算法已替换为SHA512。"
      found_issues=1
    else
      echo "$pam_file 中已配置强哈希算法，无需修复。"
    fi
  done

  if [ "$found_issues" -eq 0 ]; then
    echo "所有配置文件均已符合强哈希算法要求，无需修复。"
  fi
}

# 自测功能
self_test() {
  echo "自测模式: 检查哈希算法配置。"

  for pam_file in "/etc/pam.d/system-auth" "/etc/pam.d/password-auth"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      continue
    fi

    if grep -q "pam_unix.so.*\(md5\|sha1\|sha256\)" "$pam_file"; then
      echo "自测失败: $pam_file 中存在弱哈希算法。"
      return 1
    else
      echo "自测成功: $pam_file 中哈希算法符合要求。"
    fi
  done

  return 0
}

# 参数解析函数
parse_arguments() {
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
    shift
  done
}

# 主逻辑执行
parse_arguments "$@"
fix_password_hash_algorithm


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


# 函数：修复弱口令字典设置
fix_weak_password_dict() {
  local pwquality_file="/etc/security/pwquality.conf"

  # 确保 pwquality.conf 存在
  if [ ! -f "$pwquality_file" ]; then
    echo "警告: 配置文件 $pwquality_file 未找到。"
    return 1
  fi

  # 确保没有 dictcheck=0
  if grep -q "dictcheck=0" "$pwquality_file"; then
    echo "修复: 移除 $pwquality_file 中的 dictcheck=0 配置。"
    sed -i "/dictcheck=0/d" "$pwquality_file"
    echo "修复成功: 移除了 $pwquality_file 中的 dictcheck=0 配置。"
  else
    echo "$pwquality_file 中已配置弱口令字典检查，无需修复。"
  fi
}

# 自测功能
self_test() {
  local pwquality_file="/etc/security/pwquality.conf"

  echo "自测模式: 模拟设置弱口令字典检查。"

  # 确保 pwquality.conf 存在
  if [ ! -f "$pwquality_file" ]; then
    echo "警告: 配置文件 $pwquality_file 未找到，无法进行自测。"
    return 1
  fi

  # 模拟写入 dictcheck=0
  echo "dictcheck=0" >> "$pwquality_file"
  echo "已写入 dictcheck=0 到 $pwquality_file。"

  # 调用修复函数
  fix_weak_password_dict

  # 检查修复结果
  if grep -q "dictcheck=0" "$pwquality_file"; then
    echo "自测失败: 仍然存在 dictcheck=0 配置。"
    return 1
  else
    echo "自测成功: dictcheck=0 已成功移除。"
    return 0
  fi
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

# 执行修复
fix_weak_password_dict


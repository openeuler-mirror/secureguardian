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
# Description: Security Baseline Fix Script Template with Safety Checks and Post-Repair Verification
#
# #######################################################################################

# 功能说明:
# 本脚本用于卸载不符合安全基线要求的客户端或服务，如FTP、TFTP、Telnet等，确保系统安全。脚本包含安全性检查和修复后验证步骤。

# 默认配置
PACKAGE_NAME="$1"

# 安全性检查: 确保不会误删关键系统包
safety_check() {
  local critical_packages=("kernel" "glibc" "systemd" "bash" "coreutils" "filesystem" "util-linux" "init" "libc" "openssh" "networkmanager" "pam" "rpm")

  for package in "${critical_packages[@]}"; do
    if [[ "$PACKAGE_NAME" == "$package" ]]; then
      echo "安全检查失败: $PACKAGE_NAME 是系统关键包，不能卸载。"
      return 1
    fi
  done

  return 0
}

# 修复方法: 使用 rpm -e --nodeps 卸载不符合要求的客户端，避免误删其他包
fix_unwanted_package() {
  # 查找确切的已安装包
  local installed_packages
  installed_packages=$(rpm -q "$PACKAGE_NAME")

  if [[ $? -ne 0 ]]; then
    echo "$PACKAGE_NAME 未安装，无需卸载。"
    return 0  # 未安装，返回成功
  fi

  # 遍历并卸载所有匹配的包（包括版本号）
  for package in $installed_packages; do
    echo "正在卸载 $package..."
    rpm -e --nodeps "$package"
    if [[ $? -ne 0 ]]; then
      echo "修复失败: 无法卸载 $package。"
      return 1
    fi
  done

  # 修复后验证: 确认所有相关包是否已成功卸载
  if rpm -q "$PACKAGE_NAME" &>/dev/null; then
    echo "修复失败: $PACKAGE_NAME 未完全卸载。"
    return 1
  else
    echo "修复成功: 已成功卸载 $PACKAGE_NAME。"
    return 0
  fi
}

# 进行安全性检查
safety_check
if [[ $? -ne 0 ]]; then
  exit 1
fi

# 调用修复函数并处理返回值
fix_unwanted_package
exit $?


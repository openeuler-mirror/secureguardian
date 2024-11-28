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
# Description: Security Baseline Check Script for 2.3.3
#
# #######################################################################################
# 功能说明:
# 本脚本用于确保系统登录界面的警告信息文件包含合理的内容，避免暴露系统信息。
# 支持检查并修复文件内容，权限设置为644，并提供--self-test选项进行自测。

# 默认警告信息内容
default_banner="警告：本系统为授权用户专用。未授权访问将被追踪并受到法律制裁。"
files=("/etc/motd" "/etc/issue" "/etc/issue.net")

# 设置默认权限
set_file_permissions() {
  local file="$1"
  chmod 644 "$file"
  chown root:root "$file"
  echo "$file 的权限已设置为 644，所有权已设置为 root。"
}

# 设置警告信息内容
set_warning_banner() {
  local file="$1"
  echo "$default_banner" > "$file"
  echo "$file 的警告信息已更新。"
}

# 修复警告信息和权限
apply_warning_banners() {
  for file in "${files[@]}"; do
    # 设置文件内容为默认警告信息
    set_warning_banner "$file"
    # 设置文件权限
    set_file_permissions "$file"
  done
  echo "所有警告信息文件已更新，权限设置完成。"
}

# 自测功能，模拟修复场景
self_test() {
  echo "自测: 模拟修复警告信息文件并验证权限设置。"
  local test_file="/tmp/test_warning_banner"

  # 创建临时测试文件
  cp "${files[0]}" "$test_file"

  # 进行修复
  set_warning_banner "$test_file"
  set_file_permissions "$test_file"

  # 验证测试文件内容和权限
  if grep -q "$default_banner" "$test_file" && [[ $(stat -c "%a" "$test_file") == "644" ]] && [[ $(stat -c "%U" "$test_file") == "root" ]]; then
    echo "自测成功：测试文件内容和权限均正确。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：测试文件内容或权限未正确设置。"
    rm "$test_file"
    return 1
  fi
}

# 检查参数是否为 --self-test
if [[ "$1" == "--self-test" ]]; then
  self_test
  exit $?
fi

# 执行修复
apply_warning_banners

# 返回成功状态
exit 0


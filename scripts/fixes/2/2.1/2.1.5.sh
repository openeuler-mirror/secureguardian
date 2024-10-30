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
# Description: Security Baseline Fix Script for 2.1.2
#
# #######################################################################################

#!/bin/bash

# 功能说明:
# 本脚本用于修复 /etc 目录下关键文件的权限，包括 passwd、shadow、group 等文件，确保其权限符合安全要求。
# 支持 --self-test 参数进行验证。

# 定义预期的文件权限
declare -A expected_permissions=(
  ["/etc/passwd"]="0644"
  ["/etc/shadow"]="0000"
  ["/etc/group"]="0644"
  ["/etc/gshadow"]="0000"
  ["/etc/passwd-"]="0644"
  ["/etc/shadow-"]="0000"
  ["/etc/group-"]="0644"
  ["/etc/gshadow-"]="0000"
)

# 参数解析函数，支持 --self-test 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [--self-test]"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 自测功能
self_test() {
  echo "自测模式: 修改文件权限以模拟错误，并运行修复。"

  # 备份原始权限
  chmod 0666 /etc/passwd
  chmod 0666 /etc/group

  # 执行修复
  fix_file_permissions

  # 验证修复结果
  if [[ $(stat -c "%a" /etc/passwd) == "644" ]] && [[ $(stat -c "%a" /etc/group) == "644" ]]; then
    echo "自测成功: 文件权限已成功恢复。"
    return 0
  else
    echo "自测失败: 文件权限未正确恢复。"
    return 1
  fi
}

# 修复文件权限函数
fix_file_permissions() {
  for file in "${!expected_permissions[@]}"; do
    if [[ -e "$file" ]]; then
      echo "修复: 设置 $file 的权限为 ${expected_permissions[$file]} 并确保属主和属组为 root:root。"
      chown root:root "$file"
      chmod "${expected_permissions[$file]}" "$file"
      if [[ $? -eq 0 ]]; then
        echo "修复成功: $file 的权限已设置为 ${expected_permissions[$file]}。"
      else
        echo "修复失败: 无法设置 $file 的权限。"
        return 1
      fi
    else
      echo "跳过: 文件 $file 不存在。"
    fi
  done
  return 0
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_file_permissions; then
  echo "修复完成: 所有文件权限已正确设置。"
  exit 0
else
  echo "修复失败: 部分文件权限未能正确设置。"
  exit 1
fi


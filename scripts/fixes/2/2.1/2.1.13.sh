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
# Description: Security Baseline Fix Script for 2.1.13
#
# #######################################################################################

#!/bin/bash

# 功能说明:
# 本脚本用于检测并删除所有用户 Home 目录中的 .forward 文件，确保邮件不会意外转发。
# 支持 --self-test 参数验证逻辑，并提供例外用户和对 root 用户的特殊处理。

# 初始化例外用户列表
exceptions=("halt" "sync" "shutdown" "root")

# 参数解析函数，支持 -e、--check-root 和 --self-test 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a user_exceptions <<< "$2"
        exceptions+=("${user_exceptions[@]}")
        shift 2
        ;;
      --check-root)
        # 明确要求检查 root 用户
        exceptions=("${exceptions[@]/root}")
        shift
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e user1,user2,...] [--check-root] [--self-test]"
        exit 1
        ;;
    esac
  done
}

# 自测功能：创建测试用户，并在其 Home 目录中添加 .forward 文件
self_test() {
  echo "自测模式: 创建测试用户 testuser，并模拟存在 .forward 文件的情况。"

  # 删除已有的测试用户
  if id testuser &>/dev/null; then
    echo "删除已存在的测试用户 testuser..."
    userdel -r testuser
  fi

  # 创建测试用户
  useradd -m testuser
  echo "已创建测试用户 testuser。"

  # 创建 .forward 文件
  touch /home/testuser/.forward
  echo "已在 /home/testuser 目录中创建 .forward 文件。"

  # 执行修复
  fix_forward_files

  # 验证修复结果
  if [ ! -f /home/testuser/.forward ]; then
    echo "自测成功: 已成功删除 .forward 文件。"
    userdel -r testuser
    return 0
  else
    echo "自测失败: 未能正确删除 .forward 文件。"
    return 1
  fi
}

# 修复函数：查找并删除 .forward 文件
fix_forward_files() {
  local home_directories=$(awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") {print $6}' /etc/passwd)

  for home in $home_directories; do
    user=$(basename "$home")

    # 检查是否在例外用户列表中
    if [[ " ${exceptions[*]} " =~ " ${user} " ]]; then
      echo "跳过例外用户: $user"
      continue
    fi

    # 查找并删除 .forward 文件
    if [ -f "$home/.forward" ]; then
      echo "发现并删除用户 $user 的 .forward 文件: $home/.forward"
      rm -f "$home/.forward"
      if [[ $? -eq 0 ]]; then
        echo "修复成功: 已删除用户 $user 的 .forward 文件。"
      else
        echo "修复失败: 无法删除用户 $user 的 .forward 文件。"
        return 1
      fi
    fi
  done
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_forward_files; then
  echo "修复完成: 所有 .forward 文件已删除（如有存在）。"
  exit 0
else
  echo "修复失败: 部分 .forward 文件未能正确删除。"
  exit 1
fi


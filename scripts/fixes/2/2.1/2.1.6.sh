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
# Description: Security Baseline Fix Script for 2.1.6
#
# #######################################################################################

# 功能说明:
# 本脚本用于修复用户的 Home 目录问题。确保每个用户都有自己的 Home 目录，并且目录的属主是该用户。
# 支持 --self-test 参数，用于验证修复逻辑。

# 默认例外用户列表（root 为默认例外）
EXCEPTIONS=("root")

# 参数解析函数，支持 --self-test 和 -e 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a custom_exceptions <<< "$2"
        EXCEPTIONS+=("${custom_exceptions[@]}")
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e 用户列表] [--self-test]"
        echo "  -e: 指定例外用户列表，多个用户用逗号分隔"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试用户 testuser，并删除其 Home 目录以模拟错误。"

  # 检查是否存在同名用户，如果有则先删除
  if id testuser &>/dev/null; then
    echo "删除已存在的测试用户 testuser..."
    userdel -r testuser
  fi

  # 创建测试用户并删除 Home 目录
  useradd -m testuser
  rm -rf /home/testuser
  echo "已删除 testuser 的 Home 目录，开始修复..."

  # 执行修复
  fix_user_home_directories

  # 验证修复结果
  if [[ -d /home/testuser && $(stat -c '%U' /home/testuser) == "testuser" ]]; then
    echo "自测成功: testuser 的 Home 目录已成功恢复且属主正确。"
    userdel -r testuser
    return 0
  else
    echo "自测失败: testuser 的 Home 目录未正确恢复或属主不正确。"
    return 1
  fi
}

# 修复用户 Home 目录函数
fix_user_home_directories() {
  # 遍历所有用户，确保其 Home 目录存在且属主正确
  while IFS=: read -r user _ uid _ _ home shell; do
    if [[ " ${EXCEPTIONS[*]} " =~ " ${user} " ]]; then
      echo "跳过例外用户: $user"
      continue
    fi

    if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" || "$shell" == "/usr/sbin/nologin" ]]; then
      echo "跳过非登录用户: $user"
      continue
    fi

    if [ ! -d "$home" ]; then
      echo "修复: 创建 $user 的 Home 目录 $home。"
      mkdir -p "$home"
      chown "$user:$user" "$home"
      chmod 700 "$home"
    elif [[ $(stat -c '%U' "$home") != "$user" ]]; then
      echo "修复: 修改 $home 的属主为 $user。"
      chown "$user:$user" "$home"
    fi
  done < <(awk -F':' '$3>=1000 && $3!=65534 {print $0}' /etc/passwd)
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_user_home_directories; then
  echo "修复完成: 所有用户的 Home 目录已正确设置。"
  exit 0
else
  echo "修复失败: 部分用户的 Home 目录未能正确设置。"
  exit 1
fi


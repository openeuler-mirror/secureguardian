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
# Description: Security Baseline Check Script for 2.1.3
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于修复系统中不同用户账号初始分配了相同组ID的问题。
# 如果检测到不同用户共享同一个组ID，会为每个用户创建一个独立的组，并将该用户移动到新组中。
# 支持 --self-test 参数，用于验证修复逻辑。

# 默认例外组ID（root 组ID默认排除）
EXCEPTION_GROUP_IDS=("0")

# 参数解析函数，支持 --self-test 和 -e 参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e)
        IFS=',' read -r -a custom_exceptions <<< "$2"
        EXCEPTION_GROUP_IDS+=("${custom_exceptions[@]}")
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-e 组ID列表] [--self-test]"
        echo "  -e: 指定例外组ID列表，多个组ID用逗号分隔"
        echo "  --self-test: 启用自测模式"
        exit 1
        ;;
    esac
  done
}

# 自测功能
self_test() {
  echo "自测模式: 创建测试用户 testuser1 和 testuser2，分配相同组ID。"
  groupadd testgroup
  useradd -g testgroup testuser1
  useradd -g testgroup testuser2

  echo "运行修复..."
  fix_duplicate_gid

  echo "验证自测结果..."
  local gid_testgroup=$(getent group testgroup | cut -d: -f3)
  local user1_gid=$(id -g testuser1)
  local user2_gid=$(id -g testuser2)

  if [[ "$user1_gid" != "$gid_testgroup" && "$user2_gid" != "$gid_testgroup" ]]; then
    echo "自测成功: 重复的组ID已修复。"
    userdel -r testuser1
    userdel -r testuser2
    groupdel testgroup
    return 0
  else
    echo "自测失败: 组ID修复不正确。"
    return 1
  fi
}

# 修复重复的组ID问题
fix_duplicate_gid() {
  local duplicate_gids=$(awk -F':' '!('$(IFS=\| ; echo "${EXCEPTION_GROUP_IDS[*]}")'~$4){print $4}' /etc/passwd | sort | uniq -c | awk '$1 > 1 {print $2}')

  for gid in $duplicate_gids; do
    echo "处理重复的组ID: $gid"
    local users=$(awk -F':' -v gid="$gid" '$4 == gid {print $1}' /etc/passwd)

    for user in $users; do
      if [[ "$user" != "root" ]]; then
        echo "为用户 $user 创建新组..."
        groupadd "$user"
        usermod -g "$user" "$user"
        if [[ $? -eq 0 ]]; then
          echo "修复成功: 用户 $user 已移动到新组 $user。"
        else
          echo "修复失败: 无法将用户 $user 移动到新组。"
          return 1
        fi
      fi
    done
  done
  return 0
}

# 解析参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_duplicate_gid; then
  echo "修复完成: 所有重复的组ID已被修复。"
  exit 0
else
  echo "修复失败: 无法修复所有重复的组ID。"
  exit 1
fi


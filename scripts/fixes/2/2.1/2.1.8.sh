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
# Description: Security Baseline Fix Script for 2.1.8
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于修复系统中存在重复 UID 的问题，确保每个用户的 UID 唯一。
# 支持 --self-test 参数用于验证修复逻辑。

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

# 获取系统中未占用的最小可用 UID
get_next_available_uid() {
  local uid=1000  # 从 1000 开始，因为通常系统用户 UID 小于 1000
  while getent passwd "$uid" &>/dev/null; do
    uid=$((uid + 1))
  done
  echo "$uid"
}

# 自测功能
self_test() {
  echo "自测模式: 创建两个测试用户 testuser1 和 testuser2，并手动设置相同的 UID。"

  # 检查并删除已存在的测试用户
  for user in testuser1 testuser2; do
    if id "$user" &>/dev/null; then
      echo "删除已存在的测试用户 $user..."
      userdel -r "$user"
    fi
  done

  # 创建两个测试用户，并设置相同的 UID
  useradd -u 1001 testuser1
  useradd -u 1001 testuser2
  echo "已为 testuser1 和 testuser2 设置相同的 UID 1001，开始修复..."

  # 执行修复
  fix_duplicate_uids

  # 验证修复结果
  local uid1=$(id -u testuser1 2>/dev/null)
  local uid2=$(id -u testuser2 2>/dev/null)
  if [[ "$uid1" != "$uid2" ]]; then
    echo "自测成功: 重复的 UID 已成功修复。"
    userdel -r testuser1
    userdel -r testuser2
    return 0
  else
    echo "自测失败: UID 修复不正确。"
    return 1
  fi
}

# 修复重复的 UID 函数
fix_duplicate_uids() {
  local duplicate_uids=$(awk -F':' '{print $3}' /etc/passwd | sort | uniq -d)

  if [ -n "$duplicate_uids" ]; then
    echo "发现重复的 UID: $duplicate_uids，开始修复..."
    for uid in $duplicate_uids; do
      local users=$(awk -F':' -v uid="$uid" '$3 == uid {print $1}' /etc/passwd)
      for user in $users; do
        local new_uid=$(get_next_available_uid)
        echo "修复: 为用户 $user 分配新的 UID $new_uid..."
        usermod -u "$new_uid" "$user"
        if [[ $? -eq 0 ]]; then
          echo "修复成功: 用户 $user 的 UID 已修改为 $new_uid。"
        else
          echo "修复失败: 无法修改用户 $user 的 UID。"
          return 1
        fi
      done
    done
  else
    echo "所有 UID 均唯一，无需修复。"
  fi
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
echo "正在执行修复..."
if fix_duplicate_uids; then
  echo "修复完成: 所有用户的 UID 已正确设置。"
  exit 0
else
  echo "修复失败: 部分用户的 UID 未能正确设置。"
  exit 1
fi



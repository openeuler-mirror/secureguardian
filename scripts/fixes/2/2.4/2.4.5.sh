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
# Description: 修复脚本，确保普通用户通过 sudo 执行特权程序，注释掉不合法项
#
# #######################################################################################

# 使用说明
usage() {
  echo "用法: $0 [-e 用户1,用户2] [--self-test]"
  echo "示例: $0 -e user1,user2"
  echo "默认修复/etc/sudoers中不合法的sudo配置，注释掉不符合要求的用户配置。"
  echo "可通过-e指定例外用户，这些用户的配置将不会被修复。"
  echo "使用--self-test模拟问题场景并验证修复逻辑。"
}

# 初始化参数
EXCLUDE=""

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--exceptions)
      EXCLUDE="$2"
      shift 2
      ;;
    --self-test)
      SELF_TEST=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "无效选项: $1"
      usage
      exit 1
      ;;
  esac
done

SUDOERS_FILE="/etc/sudoers"
SUDOERS_TMP="/etc/sudoers.tmp"

# 注释不合法sudo权限的函数
fix_sudo_permissions() {
  local exclude="$1"

  # 备份原始 sudoers 文件
  cp "$SUDOERS_FILE" "$SUDOERS_FILE.bak.$(date +%F_%T)"
  echo "已备份 $SUDOERS_FILE 至 $SUDOERS_FILE.bak.$(date +%F_%T)"

  # 创建临时文件
  touch "$SUDOERS_TMP"

  while IFS= read -r line; do
    # 忽略注释和默认设置行
    if [[ "$line" =~ ^# ]] || [[ "$line" =~ ^Defaults ]]; then
      echo "$line" >> "$SUDOERS_TMP"
      continue
    fi

    # 提取用户名或用户组
    user=$(echo "$line" | awk '{print $1}')
   
    if [[ -z "$user" ]]; then
      echo "$line" >> "$SUDOERS_TMP"
      continue
    fi 
    
    # 检查用户是否被排除
    if [[ ",$exclude," == *",$user,"* ]] || [[ "$user" == "root" ]] || [[ "$user" == "%wheel" ]]; then
      echo "$line" >> "$SUDOERS_TMP"
      continue
    fi

    # 如果该用户配置了sudo权限且未排除，则注释掉该行
    echo "# 检测到未授权用户配置了sudo权限，已注释: $user" >> "$SUDOERS_TMP"
    echo "# $line" >> "$SUDOERS_TMP"
  done < "$SUDOERS_FILE"

  # 替换原始 sudoers 文件为修复后的文件
  mv "$SUDOERS_TMP" "$SUDOERS_FILE"
  echo "修复完成: 不合法的 sudo 配置已注释。"
}

# 自测功能
self_test() {
  echo "自测: 创建测试场景。"

  # 备份当前 sudoers 文件
  cp "$SUDOERS_FILE" "$SUDOERS_FILE.bak.self_test.$(date +%F_%T)"

  # 添加测试内容到 sudoers 文件
  echo "testuser ALL=(ALL) NOPASSWD: /bin/ls" >> "$SUDOERS_FILE"
  echo "模拟添加不合法配置: testuser"

  # 执行修复
  fix_sudo_permissions ""

  # 检查修复结果
  if grep -q "^# testuser ALL=(ALL) NOPASSWD: /bin/ls" "$SUDOERS_FILE"; then
    echo "自测成功: 不合法配置已被正确注释。"
    # 恢复原 sudoers 文件
    mv "$SUDOERS_FILE.bak.self_test.$(date +%F_%T)" "$SUDOERS_FILE"
    return 0
  else
    echo "自测失败: 未能正确注释不合法配置。"
    # 恢复原 sudoers 文件
    mv "$SUDOERS_FILE.bak.self_test.$(date +%F_%T)" "$SUDOERS_FILE"
    return 1
  fi
}

# 主函数
main() {
  if [[ "$SELF_TEST" == true ]]; then
    self_test
    exit $?
  fi

  if [ ! -f "$SUDOERS_FILE" ]; then
    echo "指定的 sudoers 文件不存在: $SUDOERS_FILE"
    exit 1
  fi

  fix_sudo_permissions "$EXCLUDE"
  exit 0
}

# 执行主函数
main "$@"


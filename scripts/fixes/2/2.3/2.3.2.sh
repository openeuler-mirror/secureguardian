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
# Description: Security Baseline Check Script for 2.3.2
#
# #######################################################################################
# 功能说明:
# 本脚本用于确保会话超时时间设置在 /etc/profile 文件中，默认超时时间为 300 秒。
# 支持通过参数自定义会话超时时间，默认值为 300。
# 该脚本提供 --self-test 选项，用于自测验证配置。

# 默认会话超时时间（秒）
default_timeout=300
profile_file="/etc/profile"

# 自测功能，模拟修复场景
self_test() {
  echo "自测: 模拟配置会话超时时间并验证。"
  test_file="/tmp/profile-test"
  cp "$profile_file" "$test_file"

  # 临时修改文件路径
  profile_file="$test_file"
  apply_session_timeout

  # 检查设置是否正确
  if grep -Eq "^export[[:space:]]+TMOUT=$default_timeout" "$test_file"; then
    echo "自测成功：会话超时时间已正确设置为 $default_timeout 秒。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：会话超时时间未正确设置。"
    rm "$test_file"
    return 1
  fi
}

# 备份 /etc/profile 文件
backup_profile_file() {
  cp "$profile_file" "${profile_file}.bak.$(date +%F_%T)"
  echo "已备份 $profile_file 至 ${profile_file}.bak.$(date +%F_%T)"
}

# 应用会话超时设置，确保灵活处理不同格式
apply_session_timeout() {
  backup_profile_file

  # 正则表达式匹配各种 TMOUT 行格式
  local tmout_regex="^[[:space:]]*(export[[:space:]]+)?TMOUT=.*"

  # 检查并更新 TMOUT 设置
  if grep -Eq "$tmout_regex" "$profile_file"; then
    sed -i "s/$tmout_regex/export TMOUT=$default_timeout/" "$profile_file"
  else
    echo "export TMOUT=$default_timeout" >> "$profile_file"
  fi

  echo "$profile_file 配置已更新：会话超时时间设置为 $default_timeout 秒。"
  # 使配置立即生效
  source "$profile_file"
}

# 解析命令行参数
while getopts ":t:-:" opt; do
  case ${opt} in
    t ) default_timeout=$OPTARG ;;
    - )
      case "${OPTARG}" in
        self-test) self_test; exit $? ;;
        *) echo "未知选项 --${OPTARG}" ;;
      esac ;;
    \? ) echo "用法: $0 [-t 超时时间（秒）] [--self-test]" ;;
  esac
done

# 只有在未指定 --self-test 时才执行 apply_session_timeout
apply_session_timeout

# 返回成功状态
exit 0


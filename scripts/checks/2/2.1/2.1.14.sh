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
# Description: Security Baseline Check Script for 2.1.14
#
# #######################################################################################

# Initialize an array for excluded users
declare -a excluded_users=("halt" "sync" "shutdown")

# Optionally, parse additional excluded users passed as arguments
while getopts "e:" opt; do
  case ${opt} in
    e ) IFS=',' read -r -a user_input <<< "${OPTARG}"
        excluded_users+=("${user_input[@]}")
        ;;
    \? ) echo "Usage: cmd [-e excluded_user1,excluded_user2,...]"
        exit 1
        ;;
  esac
done

# Function to check for .netrc files in home directories
check_netrc_files() {
  local found=false

  while IFS=: read -r user pass uid gid full home shell; do
    # Skip users with no login shell or excluded users
    if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" || " ${excluded_users[@]} " =~ " ${user} " ]]; then
      continue
    fi

    # Search for .netrc files
    if [[ -f "${home}/.netrc" ]]; then
      echo "检测失败: 用户 ${user} 的Home目录下存在 .netrc 文件"
      found=true
    fi
  done < /etc/passwd

  if [[ "$found" == false ]]; then
    echo "检测成功: 所有用户的Home目录下均不存在 .netrc 文件。"
    return 0
  else
    return 1
  fi
}

# Run the check and exit with the corresponding status
if check_netrc_files; then
  exit 0
else
  exit 1
fi


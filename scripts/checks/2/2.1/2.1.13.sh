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
# Description: Security Baseline Check Script for 2.1.13
#
# #######################################################################################

# 初始化例外用户列表为空
exceptions=("halt" "sync" "shutdown")

# 显示帮助信息的函数
show_help() {
  echo "Usage: $0 [-e user1,user2,...]"
  echo "  -e Specify a comma-separated list of users to exclude from the check."
  echo "  -h Display this help message and exit."
}

# 解析命令行参数
while getopts ":e:h" opt; do
  case ${opt} in
    e )
      IFS=',' read -r -a user_exceptions <<< "${OPTARG}"
      exceptions+=("${user_exceptions[@]}")
      ;;
    h )
      show_help
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      show_help
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      show_help
      exit 1
      ;;
  esac
done

# 检查.forward文件的函数
check_forward_files() {
  local home_directories=$(awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") {print $6}' /etc/passwd)
  
  for home in $home_directories; do
    # 获取当前用户名
    user=$(basename "$home")
    # 如果用户在例外列表中，则跳过检查
    if [[ " ${exceptions[*]} " =~ " ${user} " ]]; then
        echo "Skipping user $user"
        continue
    fi

    # 查找.forward文件
    local forward_files=$(find "$home" -maxdepth 1 -type f -name ".forward" 2>/dev/null)
    
    if [[ ! -z "$forward_files" ]]; then
      echo "检测失败: 用户 $user 的Home目录下存在.forward文件"
      return 1
    fi
  done

  echo "检查通过，不存在.forward文件。"
  return 0
}

# 调用函数并处理返回值
if check_forward_files; then
  exit 0
else
  exit 1
fi


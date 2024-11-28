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
# Description: Security Baseline Check Script for 2.4.1
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于限制历史命令记录的数量，默认设置为100条。
# 支持通过参数自定义记录数量，默认范围为1-100。
# 提供 --self-test 选项以在测试环境中验证功能。

# 默认历史命令记录数量
default_hist_size=100
profile_file="/etc/profile"

# 备份 /etc/profile 文件
backup_profile_file() {
  cp "$profile_file" "${profile_file}.bak.$(date +%F_%T)"
  echo "已备份 $profile_file 至 ${profile_file}.bak.$(date +%F_%T)"
}

# 设置 HISTSIZE
apply_hist_size() {
  local hist_size=${1:-$default_hist_size}

  # 检查是否已存在 HISTSIZE 设置
  if grep -qiP "^HISTSIZE" "$profile_file"; then
    sed -i "s/^HISTSIZE=.*/HISTSIZE=$hist_size/" "$profile_file"
  else
    echo "HISTSIZE=$hist_size" >> "$profile_file"
  fi

  echo "$profile_file 中的HISTSIZE已设置为 $hist_size。"
  # 使配置立即生效
  source "$profile_file"
}

# 自测功能，模拟设置 HISTSIZE
self_test() {
  echo "自测: 模拟配置 HISTSIZE 并验证。"
  local test_file="/tmp/profile_test"

  # 创建临时测试文件
  cp "$profile_file" "$test_file"

  # 设置测试文件路径
  profile_file="$test_file"
  apply_hist_size

  # 验证设置是否正确
  if grep -q "^HISTSIZE=$default_hist_size" "$test_file"; then
    echo "自测成功：测试文件中的 HISTSIZE 配置正确。"
    rm "$test_file"
    return 0
  else
    echo "自测失败：HISTSIZE 配置未正确应用。"
    rm "$test_file"
    return 1
  fi
}

# 解析命令行参数
hist_size_target=""
while getopts ":s:-:" opt; do
  case ${opt} in
    s) hist_size_target=$OPTARG ;;
    -)
      case "${OPTARG}" in
        self-test) self_test; exit $? ;;
        *) echo "未知选项 --${OPTARG}" ;;
      esac ;;
    \?) echo "用法: $0 [-s 记录数量] [--self-test]" ;;
  esac
done

# 使用自定义的或默认的 HISTSIZE 设置
hist_size=${hist_size_target:-$default_hist_size}

# 检查历史记录数量是否在1-100范围内
if [[ "$hist_size" -lt 1 || "$hist_size" -gt 100 ]]; then
  echo "错误：历史记录数量应在1到100之间。"
  exit 1
fi

# 执行配置
apply_hist_size "$hist_size"

# 返回成功状态
exit 0


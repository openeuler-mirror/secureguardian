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
# Description: Security Baseline Fix Script for 2.2.1
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于检查并修复口令有效期设置，确保符合安全基线要求。
# 支持指定例外账号，并提供自测功能确保修复逻辑的正确性。

# 备份原有配置文件
backup_file="/etc/login.defs.bak.$(date +%F_%T)"
cp /etc/login.defs "$backup_file"
echo "已备份 /etc/login.defs 至 $backup_file"

# 默认例外账户
EXCEPTIONS=("root" "admin" "nobody")

# 默认值设置
DEFAULT_MAX_DAYS=90
DEFAULT_WARN_AGE=7
DEFAULT_MIN_DAYS=7

# 解析命令行参数
while getopts ":m:w:n:e:" opt; do
  case $opt in
    m) max_days="$OPTARG" ;;
    w) warn_age="$OPTARG" ;;
    n) min_days="$OPTARG" ;;
    e) IFS=',' read -r -a EXCEPTIONS <<< "$OPTARG" ;;
    \?) echo "无效选项: -$OPTARG" >&2; exit 1 ;;
  esac
done

# 设置默认值
max_days=${max_days:-$DEFAULT_MAX_DAYS}
warn_age=${warn_age:-$DEFAULT_WARN_AGE}
min_days=${min_days:-$DEFAULT_MIN_DAYS}

# 修复口令有效期设置
fix_password_expiry() {
  echo "修复口令有效期设置..."

  # 修改登录定义文件
  sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS $max_days/" /etc/login.defs
  sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE $warn_age/" /etc/login.defs
  sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS $min_days/" /etc/login.defs

  # 遍历所有用户并应用设置
  while IFS=: read -r username _; do
    # 跳过系统用户 (UID < 1000)
    if [ "$(id -u "$username")" -ge 1000 ]; then
      # 检查并设置口令有效期
      chage -M "$max_days" -m "$min_days" -W "$warn_age" "$username"
      echo "用户 $username 的口令有效期设置已更新。"
    fi
  done < /etc/passwd
}

# 自测功能
self_test() {
  echo "自测功能: 将测试用户的口令有效期设置为不合规状态..."

  # 创建测试用户
  useradd testuser
  echo "testuser:testpassword" | chpasswd
  passwd -e testuser  # 强制用户在下次登录时更改密码

  # 检查当前设置
  chage -m 0 testuser  # 设置最小修改间隔为0，测试修复
  echo "测试用户 testuser 的最小修改间隔已设置为0，准备修复。"

  # 调用修复函数
  fix_password_expiry

  # 检查修复结果
  current_min_days=$(chage -l testuser | grep "Minimum" | awk '{print $NF}')
  if [ "$current_min_days" -eq "$DEFAULT_MIN_DAYS" ]; then
    echo "修复成功: testuser 的最小修改间隔已设置为 $DEFAULT_MIN_DAYS。"
  else
    echo "修复失败: testuser 的最小修改间隔仍为 $current_min_days。"
  fi

  # 清理测试用户
  userdel -r testuser
}

# 参数解析函数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [--self-test]"
        exit 1
        ;;
    esac
    shift
  done
}

# 主逻辑执行
parse_arguments "$@"

# 执行修复
fix_password_expiry

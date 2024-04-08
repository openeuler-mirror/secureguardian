#!/bin/bash

# 初始化例外账号数组
exceptions=("sync" "shutdown" "halt" "mockbuild")

# 解析命令行参数
while getopts "e:" opt; do
  case ${opt} in
    e )
      IFS=',' read -r -a user_exceptions <<< "${OPTARG}"
      for user_exception in "${user_exceptions[@]}"; do
          exceptions+=("$user_exception")
      done
      ;;
    \? )
      echo "使用方法: $0 [-e 账号1,账号2,...]"
      exit 1
      ;;
  esac
done

# 检查账号有效期的函数
check_account_expiration() {
  while IFS=: read -r user enc_passwd uid gid geocos home shell; do
    # 跳过例外账号
    if [[ " ${exceptions[*]} " =~ " ${user} " ]]; then
      continue
    fi

    # 跳过无需登录的账号
    if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" ]]; then
      continue
    fi

    # 从/etc/shadow获取账号的过期时间
    expire_date=$(awk -F: -v user="$user" '$1 == user {print $8}' /etc/shadow)
    if [ -z "$expire_date" ]; then
      echo "检测失败: 账号 $user 未设置过期时间。"
      return 1
    fi
  done < /etc/passwd

  echo "检测成功: 所有需要检查的账号均已设置了过期时间。"
  return 0
}

# 调用检查函数
if check_account_expiration; then
  exit 0
else
  exit 1
fi


#!/bin/bash

# 默认例外用户为root，可以通过命令行参数 -e 指定额外的例外用户
EXCEPTIONS=("root")

# 接收命令行参数
while getopts 'e:' OPTION; do
  case "$OPTION" in
    e)
      IFS=',' read -r -a CUSTOM_EXCEPTIONS <<< "$OPTARG"
      EXCEPTIONS+=("${CUSTOM_EXCEPTIONS[@]}") # 添加自定义的例外用户
      ;;
    ?)
      #echo "使用方法: $0 [-e 用户列表]"
      #echo "例子: $0 -e user1,user2"
      exit 1
      ;;
  esac
done

# 检查无需登录能力的账号
check_non_login_accounts() {
  # 查找系统中所有的账号
  all_accounts=$(awk -F':' '{print $1}' /etc/passwd)

  # 查找允许登录的账号
  login_accounts=$(grep -vE "/sbin/nologin|/bin/false" /etc/passwd | awk -F':' '{print $1}')

  # 循环检查每个允许登录的账号
  for account in $login_accounts; do
    # 检查当前账号是否在例外列表中
    if printf '%s\n' "${EXCEPTIONS[@]}" | grep -q "^$account$"; then
      echo "例外账号 $account 不检查。"
      continue # 如果是例外账号，则不检查
    fi

    # 检查账号是否锁定
    lock_status=$(passwd -S $account | awk '{print $2}')
    if [[ "$lock_status" == "L" || "$lock_status" == "LK" ]]; then
      echo "账号 $account 已被锁定，不需禁止登录。"
      continue # 如果账号已被锁定，则跳过
    fi

    # 如果账号不应该登录，但未设置为nologin或false，则报错
    shell=$(grep "^$account:" /etc/passwd | cut -d: -f7)
    if [[ "$shell" != "/sbin/nologin" && "$shell" != "/bin/false" ]]; then
      echo "检测不成功: 账号 $account 应该禁止登录。"
      return 1
    fi
  done

  echo "检测成功: 所有不该登录的账号都已正确设置。"
  return 0
}

# 调用函数并处理返回值
if check_non_login_accounts; then
  exit 0 # 检查成功，脚本退出状态为0
else
  exit 1 # 检查失败，脚本退出状态为1
fi


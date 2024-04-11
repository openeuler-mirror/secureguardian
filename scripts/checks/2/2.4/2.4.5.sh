#!/bin/bash

# 使用说明
usage() {
  echo "用法: $0 [-e 用户1,用户2]"
  echo "示例: $0 -e user1,user2"
  echo "默认检查/etc/sudoers中非root用户的所有sudo权限配置。"
  echo "可通过-e指定例外用户，这些用户的配置将不会被检查。"
}

# 解析参数
EXCLUDE=""

while getopts ":he:" opt; do
  case ${opt} in
    e )
      EXCLUDE="$OPTARG"
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      echo "无效选项: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

SUDOERS_FILE="/etc/sudoers"

# 检查sudo权限的函数
check_sudo_permissions() {
  local exclude="$1"
  local found_unauthorized=false

  while IFS= read -r line; do
    # 忽略注释和默认设置行
    if [[ "$line" =~ ^# ]] || [[ "$line" =~ ^Defaults ]]; then
      continue
    fi

    # 提取用户名或用户组
    user=$(echo "$line" | awk '{print $1}')
   
    if [[ -z "$user" ]]; then
 	 continue
    fi 
    # 检查用户是否被排除
    if [[ ",$EXCLUDE," == *",$user,"* ]] || [[ "$user" == "root" ]] || [[ "$user" == "%wheel" ]]; then
      continue
    fi
    
    if [[ ! -z "$user" ]]; then
      echo "检测到未被排除的用户配置了sudo权限: $user"
      fail=true
    fi

    echo "检测到未被排除的用户配置了sudo权限: $user"
    found_unauthorized=true

  done < "$SUDOERS_FILE"

  if [ "$found_unauthorized" = true ]; then
    return 1
  else
    echo "检测成功: 未发现非排除用户配置的sudo权限。"
    return 0
  fi
}

# 主函数
main() {
  if [ ! -f "$SUDOERS_FILE" ]; then
    echo "指定的sudoers文件不存在: $SUDOERS_FILE"
    exit 1
  fi

  if check_sudo_permissions "$EXCLUDE"; then
    exit 0
  else
    echo "检测不成功: 发现非排除用户配置了sudo权限。"
    exit 1
  fi
}

# 执行主函数
main "$@"


#!/bin/bash

# 默认的例外组ID列表，root 组ID默认排除
EXCEPTION_GROUP_IDS=("0")

# 接收命令行参数
while getopts 'e:' OPTION; do
  case "$OPTION" in
    e)
      IFS=',' read -r -a custom_exceptions <<< "$OPTARG"
      EXCEPTION_GROUP_IDS+=("${custom_exceptions[@]}") # 添加自定义的例外组ID
      ;;
    ?)
      echo "使用方法: $0 [-e 组ID列表]"
      echo "例子: $0 -e gid1,gid2"
      exit 1
      ;;
  esac
done

check_duplicate_gid() {
  # 获取所有组ID，排除例外的组ID
  local gid_occurrences=$(awk -F':' '!('$(IFS=\| ; echo "${EXCEPTION_GROUP_IDS[*]}")'~$4){print $4}' /etc/passwd | sort | uniq -c | awk '$1 > 1 {print $2}')
  
  if [ -z "$gid_occurrences" ]; then
    echo "检测成功: 没有发现初始分配了相同组ID的不同用户账号。"
    return 0
  else
    echo "检测失败: 发现初始分配了相同组ID的不同用户账号。重复的组ID: $gid_occurrences"
    return 1
  fi
}

# 调用函数并处理返回值
if check_duplicate_gid; then
  exit 0
else
  exit 1
fi


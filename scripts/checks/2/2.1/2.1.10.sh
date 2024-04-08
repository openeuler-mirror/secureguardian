#!/bin/bash

# 初始化例外GID数组
exceptions=()

# 解析命令行参数
while getopts "e:" opt; do
  case ${opt} in
    e )
      IFS=',' read -r -a exceptions <<< "${OPTARG}"
      ;;
    \? )
      echo "使用方法: $0 [-e GID1,GID2,...]"
      exit 1
      ;;
  esac
done

# 检查GID唯一性的函数
check_gid_uniqueness() {
  # 检索/etc/group中的GID并检查是否唯一
  local duplicate_gids=$(awk -F':' '{print $3}' /etc/group | sort | uniq -d)

  for gid in $duplicate_gids; do
    # 检查GID是否在例外列表中
    if printf '%s\n' "${exceptions[@]}" | grep -q "^$gid$"; then
      # 如果GID在例外列表中，忽略这个GID
      echo "例外GID $gid 被忽略。"
    else
      # 如果GID不在例外列表中，报告重复GID
      echo "检测失败: GID $gid 不唯一。"
      return 1
    fi
  done

  echo "检测成功: 所有GID唯一。"
  return 0
}

# 调用检查函数
if check_gid_uniqueness; then
  exit 0
else
  exit 1
fi


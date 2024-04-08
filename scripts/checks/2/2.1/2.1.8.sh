#!/bin/bash

# 检查/etc/passwd中UID的唯一性
check_unique_uid() {
  # 使用awk检查UID是否唯一
  local duplicate_uids=$(awk -F':' '{print $3}' /etc/passwd | sort | uniq -d)

  if [ -n "$duplicate_uids" ]; then
    echo "检测失败: 发现重复的UID"
    echo "$duplicate_uids"
    return 1
  else
    echo "检测成功: 所有UID均唯一"
    return 0
  fi
}

# 调用函数并处理返回值
if check_unique_uid; then
  exit 0
else
  exit 1
fi


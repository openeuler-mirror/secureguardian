#!/bin/bash

# 检测系统中是否存在全局可写文件
check_global_writable_files() {
  local file_found=$(find / -type f -perm -0002 ! -path "/proc/*" ! -path "/sys/*" -print -quit)
  if [ ! -z "$file_found" ]; then
    echo "发现全局可写文件: $file_found"
    exit 1
  else
    echo "未发现全局可写文件。"
    exit 0
  fi
}

# 调用检测函数
check_global_writable_files


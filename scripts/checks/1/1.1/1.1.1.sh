#!/bin/bash

# 定义检查无属主或属组的文件或目录的函数
check_files_and_dirs() {
  # 构造查找命令中的挂载点参数
  local mounts=$(df -l | sed -n '2,$p' | awk '{print $6}')

  # 检查无属主的文件或目录，找到第一个就停止，并打印它
  local no_owner=$(find $mounts -xdev -nouser 2>/dev/null | head -n 1)
  if [ ! -z "$no_owner" ]; then
    echo "找到无属主的文件或目录：$no_owner"
    return 1  # 发现问题，返回false
  fi

  # 检查无属组的文件或目录，找到第一个就停止，并打印它
  local no_group=$(find $mounts -xdev -nogroup 2>/dev/null | head -n 1)
  if [ ! -z "$no_group" ]; then
    echo "找到无属组的文件或目录：$no_group"
    return 1  # 发现问题，返回false
  fi

  # 如果未发现问题，返回true
  return 0
}

# 调用函数并处理返回值
if check_files_and_dirs; then
  #echo "检查通过，不存在无属主或属组的文件或目录。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过。"
  exit 1  # 检查未通过，脚本以失败退出
fi


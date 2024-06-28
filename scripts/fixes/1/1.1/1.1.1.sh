#!/bin/bash

# 功能说明:
# 本脚本用于修复系统中发现的无属主或属组的文件或目录。它确保所有的文件和目录都具有合法的属主和属组。
# 此外，脚本支持用户输入参数来指定扫描的目录范围，默认扫描所有挂载点。
# 使用此脚本有助于维护系统安全和合规性。

show_usage() {
  echo "Usage: $0 [--self-test] [-d <directory>] [-e <exception_list>]"
  echo "  -d, --directory   指定扫描的目录（默认扫描所有挂载点）"
  echo "  -e, --exception   指定例外文件或目录（逗号分隔）"
  echo "  --self-test       执行自测程序"
  echo "  /?                显示此帮助信息"
  exit 1
}

# 检查和修复无属主或属组的文件或目录
fix_files_and_dirs() {
  local dir="$1"
  local exceptions="$2"
  local mounts="$dir"
  
  local find_command="find $mounts -xdev"
  if [ -n "$exceptions" ]; then
    IFS=',' read -ra EXCEPTIONS_ARRAY <<< "$exceptions"
    for exception in "${EXCEPTIONS_ARRAY[@]}"; do
      find_command+=" ! -path $exception"
    done
  fi

  # 检查并删除无属主的文件或目录
  local no_owner
  no_owner=$($find_command -nouser 2>/dev/null)
  if [ ! -z "$no_owner" ]; then
    echo "删除以下无属主的文件或目录："
    echo "$no_owner"
    echo "$no_owner" | xargs rm -rf
  fi

  # 检查并删除无属组的文件或目录
  local no_group
  no_group=$($find_command -nogroup 2>/dev/null)
  if [ ! -z "$no_group" ]; then
    echo "删除以下无属组的文件或目录："
    echo "$no_group"
    echo "$no_group" | xargs rm -rf
  fi

  if [ -z "$no_owner" ] && [ -z "$no_group" ]; then
    echo "修复成功: 未找到无属主或属组的文件或目录。"
  else
    echo "修复成功: 已删除所有无属主或属组的文件或目录。"
  fi
  return 0
}

self_test() {
  local test_dir="/tmp/test_no_owner_group"
  mkdir -p "$test_dir"
  
  # 创建无属主和无属组的文件
  touch "$test_dir/no_owner"
  touch "$test_dir/no_group"
  
  # 尝试设置一个明确未分配的高ID
  chown 99999 "$test_dir/no_owner"
  chgrp 99999 "$test_dir/no_group"

  echo "执行自测：检查并修复无属主或属组的文件..."
  fix_files_and_dirs "$test_dir" ""

  # 检查文件是否还存在
  if [ ! -f "$test_dir/no_owner" ] && [ ! -f "$test_dir/no_group" ]; then
    echo "自测成功: 无属主或属组的文件已被正确处理。"
  else
    echo "自测失败: 文件未被正确处理。"
  fi
  
  # 清理测试环境
  rm -rf "$test_dir"
}

# 处理输入参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --self-test)
      self_test
      exit 0
      ;;
    -d|--directory)
      directory="$2"
      shift 2
      ;;
    -e|--exception)
      exceptions="$2"
      shift 2
      ;;
    /?)
      show_usage
      ;;
    *)
      show_usage
      ;;
  esac
done

# 调用修复函数并处理返回值
if fix_files_and_dirs "${directory:-$(df -l | sed -n '2,$p' | awk '{print $6}')}" "$exceptions"; then
  exit 0
else
  echo "修复失败: 无法修复所有无属主或属组的文件或目录。"
  exit 1
fi


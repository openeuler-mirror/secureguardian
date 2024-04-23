#!/bin/bash

# 默认配置大小（单位：MB）
DEFAULT_MAX_SIZE=8

# 函数：检查 max_log_file 配置
check_max_log_file() {
  local expected_size=$1
  local actual_size=$(awk -F'=' '/^max_log_file[[:space:]]*=/ { gsub(/[[:space:]]*/, "", $2); print $2 }' /etc/audit/auditd.conf)


  if [[ "$actual_size" -eq "$expected_size" ]]; then
      echo "检测成功: max_log_file 当前设置为 ${actual_size}MB，与期望值 ${expected_size}MB 一致。"
      return 0
  else
      echo "检测失败: max_log_file 当前设置为 ${actual_size}MB，与期望值 ${expected_size}MB 不一致。"
      return 1
  fi
}

# 解析命令行参数
while getopts ":m:" opt; do
  case ${opt} in
    m )
      max_size=$OPTARG
      ;;
    \? )
      echo "Usage: cmd [-m max_log_file_size]"
      exit 1
      ;;
  esac
done

# 如果未设置参数m，则使用默认大小
max_size=${max_size:-$DEFAULT_MAX_SIZE}

# 调用函数并处理返回值
check_max_log_file "$max_size"
exit_status=$?

# 根据检查结果退出脚本
exit $exit_status


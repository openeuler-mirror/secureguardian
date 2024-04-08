#!/bin/bash

# 定义检查全局可写目录是否设置了粘滞位的函数
check_sticky_bit() {
  # 使用find命令搜索全局可写目录但未设置粘滞位的目录
  local writable_dir=$(find / -type d -perm -0002 ! -perm -1000 -print -quit 2>/dev/null)

  if [[ ! -z $writable_dir ]]; then
    echo "找到未设置粘滞位的全局可写目录：$writable_dir"
    return 1  # 发现问题，返回false
  else
    echo "所有全局可写目录均已正确设置粘滞位。"
    return 0  # 未发现问题，返回true
  fi
}

# 调用函数并处理返回值
if check_sticky_bit; then
  #echo "检查通过。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过，存在未设置粘滞位的全局可写目录。"
  exit 1  # 检查未通过，脚本以失败退出
fi


#!/bin/bash

# 检测UMASK是否设置为0077
check_umask_setting() {
  if grep -q "umask 077" /etc/profile /etc/bashrc ~/.bashrc; then
    echo "UMASK 已正确设置为 077。"
    exit 0
  else
    echo "UMASK 未设置为 077。"
    exit 1
  fi
}

# 调用函数并处理返回值
if check_umask_setting;then
  #echo "检查通过。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过，存在未设置粘滞位的全局可写目录。"
  exit 1  # 检查未通过，脚本以失败退出
fi



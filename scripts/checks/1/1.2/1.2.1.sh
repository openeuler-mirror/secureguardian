#!/bin/bash

# 定义检测函数
check_ftp_installed() {
  if rpm -q ftp &>/dev/null; then
    return 1  # 假设找到了ftp包，不符合要求，返回1
  else
    return 0  # 没找到ftp包，符合要求，返回0
  fi
}

# 调用检测函数
check_ftp_installed

# 捕获函数返回值
retval=$?

if [ $retval -eq 0 ]; then
    echo "检测通过。"
else
    echo "检测不通过。"
fi

# 以此值退出脚本
exit $retval


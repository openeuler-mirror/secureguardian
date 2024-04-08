#!/bin/bash

# 定义检测函数
check_samba_installed() {
  # 模拟一些检测逻辑
  # 这里应该是您的检测逻辑，比如检测是否安装了某个软件包
  if rpm -q samba &>/dev/null; then
    return 1  # 假设找到了samba包，不符合要求，返回1
  else
    return 0  # 没找到samba包，符合要求，返回0
  fi
}

# 调用检测函数
check_samba_installed

# 捕获函数返回值
retval=$?

if [ $retval -eq 0 ]; then
    echo "检测通过。"
else
    echo "检测不通过,samba已经安装。"
fi

# 以此值退出脚本
exit $retval


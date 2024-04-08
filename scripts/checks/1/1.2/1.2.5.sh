#!/bin/bash

# 检测是否安装了python2
check_python2_installed() {
  if rpm -qa | grep -q "python2-"; then
    echo "检测不通过。python2已安装。"
    return 1
  else
    echo "检测通过。python2未安装。"
    return 0
  fi
}

check_python2_installed
exit $?


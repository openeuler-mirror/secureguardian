#!/bin/bash

# 检测是否安装了telnet客户端
check_telnet_installed() {
  if ! rpm -q telnet &>/dev/null; then
    echo "检测通过。Telnet客户端未安装。"
    return 0
  else
    echo "检测不通过。Telnet客户端已安装。"
    return 1
  fi
}

check_telnet_installed
exit $?


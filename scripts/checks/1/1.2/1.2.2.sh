#!/bin/bash

# 检测是否安装了tftp客户端和服务端
check_tftp_installed() {
  if rpm -q tftp &>/dev/null; then
    echo "检测不通过。TFTP客户端已安装。"
    return 1
  else
    echo "检测通过。TFTP客户端未安装。"
    return 0
  fi
}

check_tftp_installed
exit $?


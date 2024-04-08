#!/bin/bash

# 检测是否安装了不安全的SNMP协议版本
check_snmp_installed() {
  if rpm -qa | grep -qE "net-snmp-[0-9]"; then
    echo "检测不通过。SNMP版本已安装。"
    return 1
  else
    echo "检测通过。SNMP版本未安装。"
    return 0
  fi
}

check_snmp_installed
exit $?


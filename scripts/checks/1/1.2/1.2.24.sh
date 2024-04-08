#!/bin/bash

# 定义检测dhcpd服务是否启用的函数
check_dhcpd_enabled() {
  # 检查dhcpd服务是否启用
  if systemctl is-enabled dhcpd &>/dev/null; then
    echo "检测不通过。DHCP服务（dhcpd）已启用。"
    return 1
  else
    echo "检测通过。DHCP服务（dhcpd）未启用。"
    return 0
  fi
}

# 调用检测函数
check_dhcpd_enabled

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


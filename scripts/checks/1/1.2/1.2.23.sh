#!/bin/bash

# 定义检测函数
check_rpcbind_enabled() {
  # 检查rpcbind服务是否启用
  if systemctl is-enabled rpcbind &>/dev/null; then
    echo "检测不通过。rpcbind服务已启用。"
    return 1
  else
    echo "检测通过。rpcbind服务未启用。"
    return 0
  fi
}

# 调用检测函数
check_rpcbind_enabled

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


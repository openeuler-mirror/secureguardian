#!/bin/bash

# 检测debug-shell服务是否启用
check_debug_shell_enabled() {
  if systemctl is-enabled debug-shell | grep -q "disabled"; then
    echo "检测通过。debug-shell服务已禁用。"
    return 0
  else
    echo "检测不通过。debug-shell服务未禁用。"
    return 1
  fi
}

check_debug_shell_enabled
exit $?


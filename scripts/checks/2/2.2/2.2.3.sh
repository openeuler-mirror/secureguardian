#!/bin/bash

# 函数：检查用户在修改自身口令时是否需要验证旧口令
check_password_change_policy() {
  # 定义检查路径
  local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local issues=0

  for pam_file in "${pam_files[@]}"; do
    if [ ! -f "$pam_file" ]; then
      echo "警告: 配置文件 $pam_file 未找到。"
      issues=$((issues+1))
      continue
    fi

    # 检查pam_unix.so配置是否存在且不被注释
    if grep -Pq "^\s*[^#]*pam_unix.so" "$pam_file"; then
      echo "检测通过: $pam_file 中配置了要求验证旧口令。"
    else
      echo "检测失败: $pam_file 中未配置要求验证旧口令。"
      issues=$((issues+1))
    fi
  done

  # 如果两个文件都未正确配置，脚本报告失败
  if [ "$issues" -ne 0 ]; then
    echo "存在配置不符合要求，所有相关文件都需要正确配置。"
    return 1  # 检查未通过
  else
    echo "所有相关配置文件均符合要求验证旧口令的配置。"
    return 0  # 检查通过
  fi
}

# 调用函数并处理返回值
if check_password_change_policy; then
  exit 0  # 检查通过，脚本成功退出
else
  exit 1  # 存在配置不符合要求
fi


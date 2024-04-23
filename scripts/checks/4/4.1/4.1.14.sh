#!/bin/bash

# 功能说明:
# 本脚本用于检查是否已配置对 /var/run/utmp、/var/log/wtmp 和 /var/log/btmp 文件的审计规则。
# 这些文件记录了重要的会话信息，包括登录、登出和登录失败事件。
# 审计这些文件有助于管理员追踪和审查潜在的安全问题。

# 检查审计规则是否配置
function check_audit_rules {
  local missing_rules=0
  local files=("/var/run/utmp" "/var/log/wtmp" "/var/log/btmp")

  for file in "${files[@]}"; do
    if ! auditctl -l | grep -q -P "\-w\s+$file\s+\-p"; then
      echo "检测失败: $file 文件未配置任何审计规则。"
      missing_rules=1
    fi
  done

  if [ $missing_rules -ne 0 ]; then
    return 1
  fi

  echo "所有审计规则检查通过。"
  return 0
}

# 调用检查函数并处理返回值
if check_audit_rules; then
  exit 0
else
  exit 1
fi


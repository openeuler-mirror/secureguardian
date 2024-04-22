#!/bin/bash

# 功能说明:
# 本脚本用于检查是否正确配置了文件访问失败的审计规则，重点关注open、create、openat等操作。
# 如果规则中包含exit条件，将给出警告，但不会影响通过状态。

function show_usage {
  echo "用法: $0 [-a arch] [-h]"
  echo "选项:"
  echo "  -a, --arch       指定架构类型，支持 'b32' 或 'b64'，默认为 'b64'"
  echo "  -h, --help       显示帮助信息"
}

ARCH="b64"  # 默认架构类型为64位

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a|--arch)
      ARCH="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      show_usage
      exit 1
      ;;
  esac
done

# 检查文件访问失败的审计规则
function check_audit_rules {
  local syscall_errors=("EACCES" "EPERM")
  local syscalls=("open" "truncate" "ftruncate" "creat" "openat")
  local missing_rules=0
  local warnings=0

  for error in "${syscall_errors[@]}"; do
    for syscall in "${syscalls[@]}"; do
      local search_pattern="arch=$ARCH .*-S.*$syscall.*exit=-$error"
      if ! auditctl -l | grep -qiE "arch=$ARCH .*-S.*$syscall"; then
        echo "检测失败: 在$ARCH架构下，系统调用 $syscall 相关的审计规则未配置。"
        missing_rules=1
      else
        # 提供警告，如果exit字段不存在
        if ! auditctl -l | grep -qiE "$search_pattern"; then
          echo "警告: 在$ARCH架构下，系统调用 $syscall 返回 $error 的审计规则没有明确包含exit条件，可能会产生大量日志。"
          warnings=1
        fi
      fi
    done
  done

  if [ "$missing_rules" -eq 1 ]; then
    echo "存在配置错误，请检查审计规则。"
    return 1
  else
    if [ "$warnings" -eq 1 ]; then
      echo "审计规则中存在潜在的过度日志生成问题，请考虑添加具体的exit条件以减少不必要的日志输出。"
    else
      echo "所有文件访问失败相关的审计规则检查通过。"
    fi
    return 0
  fi
}

# 调用检查函数
check_audit_rules
exit_code=$?
exit $exit_code


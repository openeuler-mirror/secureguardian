#!/bin/bash

# 功能说明:
# 本脚本用于检查系统是否正确配置了文件删除操作的审计规则。
# 重点监控 rename, unlink, unlinkat, renameat 系统调用。

# 默认参数设置
ARCH="b64"  # 默认架构为64位，可以通过参数-a指定

# 显示帮助信息
function show_usage() {
  echo "Usage: $0 [-a arch]"
  echo "Options:"
  echo "  -a, --arch  指定系统架构类型 ('b32' 或 'b64'), 默认为 'b64'"
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -a|--arch)
      ARCH="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Error: Unsupported flag $1" >&2
      show_usage
      exit 1
      ;;
  esac
done

# 检查文件删除操作的审计规则
function check_file_deletion_audit_rules {
  local syscalls="rename,unlink,unlinkat,renameat"
  local audit_rules=$(auditctl -l | grep -E "$ARCH")
  local has_errors=0

  # 检查每个系统调用是否有适当的审计规则
  for syscall in ${syscalls//,/ }; do
    if ! echo "$audit_rules" | grep -qE "$syscall"; then
      echo "检测失败: 在 $ARCH 架构下，系统调用 $syscall 的审计规则未配置。"
      has_errors=1
    fi
  done

  if [[ "$has_errors" -eq 1 ]]; then
    return 1  # 如果发现错误，返回1
  else
    echo "检测通过:所有文件删除相关的审计规则检查通过。"
    return 0  # 如果一切正常，返回0
  fi
}

# 调用检查函数并处理返回值
if check_file_deletion_audit_rules; then
  exit 0
else
  exit 1
fi


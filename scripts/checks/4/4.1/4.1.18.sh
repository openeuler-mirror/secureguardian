#!/bin/bash

# 功能说明:
# 本脚本用于检查系统中文件访问控制权限的审计规则是否正确配置。
# 它将检查 chmod、chown 以及扩展属性相关系统调用的审计配置。

function show_usage {
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  -a, --arch       指定架构类型，支持 'b32' 或 'b64'，默认为 'b64'"
  echo "  -h, --help       显示帮助信息"
  exit 1
}

ARCH="b64"  # 默认架构类型为64位

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a|--arch) ARCH="$2"; shift ;;
    -h|--help) show_usage ;;
    *) echo "未知参数: $1"; show_usage; exit 1 ;;
  esac
  shift
done

# 检查审计规则配置
function check_audit_rules {
  local arch=$1
  local syscall_missing=0
  local syscalls=("chmod" "fchmod" "fchmodat" "chown" "fchown" "lchown" "fchownat" "setxattr" "lsetxattr" "fsetxattr" "removexattr" "lremovexattr" "fremovexattr")

  for syscall in "${syscalls[@]}"; do
    if ! auditctl -l | grep -qiE "arch=$arch .*-S.*$syscall"; then
      echo "检测失败: $arch 架构下系统调用 $syscall 的审计规则未配置。"
      syscall_missing=1
    fi
  done

  if [ $syscall_missing -eq 1 ]; then
    return 1
  else
    echo "检查成功:所有文件访问控制权限相关的审计规则检查通过。"
    return 0
  fi
}

# 调用检查函数
check_audit_rules $ARCH
exit_code=$?
exit $exit_code


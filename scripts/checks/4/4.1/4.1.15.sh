#!/bin/bash

# 功能说明:
# 本脚本用于检查是否正确配置了时间修改审计规则。
# 包括对关键系统时间修改调用和/etc/localtime文件的监控。

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
    -h|--help) show_usage; exit 0 ;;
    *) echo "未知参数: $1"; show_usage; exit 1 ;;
  esac
  shift
done

# 检查审计规则配置
function check_audit_rules {
  local arch=$1
  local syscalls=("settimeofday" "adjtimex" "clock_settime")

  if [ "$arch" = "b32" ]; then
    syscalls+=("stime")  # 32位系统额外监控stime调用
  fi

  local missing_rules=0

  for syscall in "${syscalls[@]}"; do
    if ! auditctl -l | grep -qiE "arch=$arch .*-S.*$syscall\b"; then
      echo "检测失败: 未配置 $arch 架构下 $syscall 的系统调用审计规则。"
      missing_rules=1
    fi
  done

  # 检查 /etc/localtime 文件的审计规则
  if ! auditctl -l | grep -qi "/etc/localtime"; then
    echo "检测失败: 未配置 /etc/localtime 文件的审计规则。"
    missing_rules=1
  fi

  if [ $missing_rules -ne 0 ]; then
    return 1
  fi

  echo "检查成功:所有审计规则检查通过。"
  return 0
}

# 调用检查函数
check_audit_rules $ARCH
exit_code=$?
if [ $exit_code -eq 0 ]; then
    exit 0
else
    exit 1
fi


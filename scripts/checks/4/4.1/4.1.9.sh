#!/bin/bash

# 功能说明:
# 本脚本用于检查是否已正确配置audit_backlog_limit参数。
# 它通过检查内核启动参数来确定audit_backlog_limit是否设置且值是否合理。

# 使用方法说明
usage() {
    echo "使用方法: $0 [-m <number> | --min-limit <number>]"
    echo "示例: $0 --min-limit 8192"
    echo "       $0 -m 8192"
    exit 1
}

# 解析命令行参数
min_limit=8192  # 默认的最小限制值
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -m | --min-limit )
    shift; min_limit=$1
    ;;
  -h | --help )
    usage
    ;;
  * )
    echo "无效参数: $1"
    usage
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# 检查audit_backlog_limit配置
check_audit_backlog_limit() {
    local cmdline=$(cat /proc/cmdline)
    local pattern="audit_backlog_limit=${min_limit}"

    if echo "$cmdline" | grep -q "$pattern"; then
        echo "检测成功: audit_backlog_limit已正确配置为${min_limit}或更高。"
        return 0
    else
        echo "检测失败: audit_backlog_limit未正确配置为${min_limit}或更高。"
        return 1
    fi
}

# 执行检查
check_audit_backlog_limit


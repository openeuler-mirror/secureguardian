#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Check Script for 4.2.7
#
# #######################################################################################

# 默认配置文件路径
LOGROTATE_CONFIG="/etc/logrotate.d/rsyslog"
RSYSLOG_CONFIG="/etc/rsyslog.conf"

# 默认rotate参数
MAXAGE=365
ROTATE=30
SIZE="4096k"

# 显示帮助信息
usage() {
    echo "用法: $0 [-c 配置文件] [-r rsyslog配置文件] [-m 最大保存天数] [-n 旋转文件数] [-s 旋转大小]"
    echo "  -c  指定logrotate配置文件 (默认: /etc/logrotate.d/rsyslog)"
    echo "  -r  指定rsyslog配置文件 (默认: /etc/rsyslog.conf)"
    echo "  -m  日志文件的最大保留天数 (默认: 365天)"
    echo "  -n  保留旋转文件的数量 (默认: 30)"
    echo "  -s  旋转日志文件的大小阈值 (默认: 4096k)"
    echo "  -h  显示此帮助信息"
    exit 0
}

# 解析命令行参数
while getopts "c:r:m:n:s:h" opt; do
    case $opt in
        c) LOGROTATE_CONFIG=$OPTARG ;;
        r) RSYSLOG_CONFIG=$OPTARG ;;
        m) MAXAGE=$OPTARG ;;
        n) ROTATE=$OPTARG ;;
        s) SIZE=$OPTARG ;;
        h) usage ;;
        *) echo "无效选项: -$OPTARG" >&2; usage ;;
    esac
done

# 检查 Rsyslog rotate 配置
check_rotate_config() {
    local fail=0
    local paths=(
        "/var/log/cron"
        "/var/log/maillog"
        "/var/log/messages"
        "/var/log/secure"
        "/var/log/spooler"
    )

    for path in "${paths[@]}"; do
        if ! grep -Pq "^[^#]*\s+-?\s*$path\b" "$RSYSLOG_CONFIG"; then
            echo "检测失败: $path 日志路径未在 $RSYSLOG_CONFIG 中正确配置或被注释。"
            fail=1
        fi
    done

    local rotate_failures=()
    [[ $(grep -cP "^\s*maxage\s+$MAXAGE\b" "$LOGROTATE_CONFIG") -eq 0 ]] && rotate_failures+=("maxage 设置应为 $MAXAGE")
    [[ $(grep -cP "^\s*rotate\s+$ROTATE\b" "$LOGROTATE_CONFIG") -eq 0 ]] && rotate_failures+=("rotate 设置应为 $ROTATE")
    [[ $(grep -cP "^\s*compress\b" "$LOGROTATE_CONFIG") -eq 0 ]] && rotate_failures+=("compress 未配置")
    [[ $(grep -cP "^\s*size\s+$SIZE\b" "$LOGROTATE_CONFIG") -eq 0 ]] && rotate_failures+=("size 设置应为 $SIZE")

    if [ ${#rotate_failures[@]} -gt 0 ]; then
        echo "检测失败: 以下 rotate 设置未在 $LOGROTATE_CONFIG 中正确配置："
        for msg in "${rotate_failures[@]}"; do
            echo "  - $msg"
        done
        fail=1
    fi

 return $fail
}

# 调用检查函数并处理返回值
if check_rotate_config; then
    exit 0
else
    exit 1
fi

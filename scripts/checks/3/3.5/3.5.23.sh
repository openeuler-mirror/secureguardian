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
# Description: Security Baseline Check Script for 3.5.23
#
# #######################################################################################

# 功能说明：
# 本脚本用于检查指定进程的seccomp状态是否符合期望值。
# 用户可以指定进程名和期望的seccomp模式（0, 1, 2）进行检查。

# 使用说明和帮助信息
usage() {
    echo "用法: $0 -p <进程名称> -e <期望的seccomp模式>"
    echo "参数:"
    echo "  -p 进程名称，例如 sshd"
    echo "  -e 期望的seccomp模式，例如 0 (禁用), 1 (严格模式), 2 (过滤模式)"
    echo "如果不提供任何参数，则脚本将检查是否有默认的seccomp支持。"
    exit 1
}

# 参数解析
while getopts ":p:e:" opt; do
  case ${opt} in
    p )
      process_name=$OPTARG
      ;;
    e )
      expected_mode=$OPTARG
      ;;
    \? )
      echo "无效选项: -$OPTARG" 1>&2
      usage
      ;;
    : )
      echo "选项 -$OPTARG 需要一个参数。" 1>&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# 检查seccomp状态的函数
check_seccomp() {
    local service_name=$1
    local expected_mode=$2
    local pids=$(pgrep -f "$service_name")

    if [[ -z "$pids" ]]; then
        echo "检测失败：找不到进程 '$service_name'。"
        return 1
    fi

    local primary_pid=""
    for pid in $pids; do
        local ppid=$(ps -o ppid= -p $pid)
        if [[ "$ppid" -eq 1 || "$(ps -o comm= -p $ppid)" == "systemd" && "$(ps -o args= -p $ppid)" == *"--user"* ]]; then
            primary_pid=$pid
            break
        fi
    done

    if [[ -z "$primary_pid" ]]; then
        echo "检测失败：无法找到由 init 或 systemd 启动的 '$service_name' 主进程。"
        return 1
    fi

    local mode=$(grep "Seccomp" /proc/"$primary_pid"/status 2>/dev/null | awk '{print $2}')
    if [[ -z "$mode" ]]; then
        echo "检测失败：无法获取进程 '$service_name' 的seccomp状态。"
        return 1
    elif [[ "$mode" != "$expected_mode" ]]; then
        echo "检测失败：'$service_name' 的seccomp状态为 $mode，与期望的 $expected_mode 不符。"
        return 1
    else
        echo "检测成功：'$service_name' 的seccomp状态为 $expected_mode。"
        return 0
    fi
}

# 如果提供了进程名称和期望的模式，就进行检查
if [[ -n "$process_name" && -n "$expected_mode" ]]; then
    check_seccomp "$process_name" "$expected_mode"
else
    echo "检测成功: 未提供足够参数，默认不检查。"
    exit 0
fi


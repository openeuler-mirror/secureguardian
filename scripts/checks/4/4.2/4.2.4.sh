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
# Description: Security Baseline Check Script for 4.2.4
#
# #######################################################################################

# 默认配置
DEFAULT_MODE="0600"
CONFIG_PATHS=("/etc/rsyslog.conf" "/etc/rsyslog.d/*.conf")

# 用法说明
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p <path>   Specify path to rsyslog configuration files. Default is '/etc/rsyslog.conf /etc/rsyslog.d/*.conf'"
    echo "  -m <mode>   Specify expected file create mode. Default is '0600'"
    echo "  -h          Display this help message"
}

# 参数解析
while getopts ":p:m:h" opt; do
  case ${opt} in
    p )
      CONFIG_PATHS=($OPTARG)
      ;;
    m )
      DEFAULT_MODE=$OPTARG
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage
      exit 1
      ;;
  esac
done

# 检查rsyslog默认文件权限
check_rsyslog_file_permissions() {
    local config_found=0
    local file_mode_correct=1

    for config in ${CONFIG_PATHS[@]}; do
        # 检查文件是否存在并搜索FileCreateMode
        if [ -f $config ]; then
            local mode=$(grep "^\\\$FileCreateMode" $config | awk '{print $2}')
            if [ -n "$mode" ]; then
                config_found=1
                echo "在配置文件 $config 中找到 FileCreateMode: $mode"
                if [ "$mode" != "$DEFAULT_MODE" ]; then
                    file_mode_correct=0
                    echo "检测失败: 文件 $config 的FileCreateMode设置不是$DEFAULT_MODE，当前设置为 $mode。"
                fi
            fi
        fi
    done

    # 检查是否有任何配置文件设置了FileCreateMode
    if [ $config_found -eq 0 ]; then
        echo "检测失败: 在配置文件中未找到任何FileCreateMode设置。"
        return 1
    elif [ $file_mode_correct -eq 0 ]; then
        return 1
    else
        echo "检查通过: 所有找到的FileCreateMode设置都为$DEFAULT_MODE。"
        return 0
    fi
}

# 调用函数并处理返回值
if check_rsyslog_file_permissions; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


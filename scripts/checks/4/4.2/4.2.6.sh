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
# Description: Security Baseline Check Script for 4.2.6
#
# #######################################################################################

# 默认配置文件路径
CONFIG_FILE="/etc/rsyslog.conf"
STATE_FILE="imjournal.state"

# 显示帮助信息
usage() {
    echo "用法: $0 [-f 配置文件路径] [-s 状态文件路径]"
    echo "  -f  指定 rsyslog 配置文件路径（默认: /etc/rsyslog.conf）"
    echo "  -s  指定 imjournal 状态文件路径（默认: /run/log/imjournal.state）"
    echo "  -h  显示帮助信息"
}

# 解析命令行参数
while getopts "f:s:h" opt; do
    case $opt in
        f) CONFIG_FILE=$OPTARG ;;
        s) STATE_FILE=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) echo "无效选项: -$OPTARG" >&2; exit 1 ;;
    esac
done

# 检查 imjournal 模块是否已配置
check_imjournal_config() {
    # 将配置文件内容读取到变量中，然后检查是否包含所需配置
    config_content=$(cat "$CONFIG_FILE" | tr '\n' ' ')

    # 使用正则表达式检查配置
    if echo "$config_content" | grep -P 'module\(load="imjournal"\s*[^)]*StateFile="'$STATE_FILE'"' > /dev/null; then
        echo "检查通过: imjournal 模块已正确配置在 $CONFIG_FILE 中，使用状态文件 $STATE_FILE。"
        exit 0
    else
        echo "检测失败: imjournal 模块未在 $CONFIG_FILE 中正确配置或状态文件 $STATE_FILE 不匹配。"
        exit 1
    fi
}

# 调用函数并处理返回值
if check_imjournal_config; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi

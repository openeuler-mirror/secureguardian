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
# Description: Security Baseline Check Script for 3.3.10
#
# #######################################################################################

# 默认SSH配置文件路径和推荐日志级别
CONFIG_FILE="/etc/ssh/sshd_config"
DEFAULT_LEVEL="VERBOSE"

# 显示帮助信息
usage() {
    echo "用法: $0 [-c 配置文件路径] [-l 日志级别] [--self-test] [-?]"
    echo "选项:"
    echo "  -c, --config       指定SSH配置文件路径 (默认: /etc/ssh/sshd_config)"
    echo "  -l, --level        指定日志级别 (默认: VERBOSE)"
    echo "  --self-test        模拟测试逻辑，验证修复效果"
    echo "  -?, --help         显示帮助信息"
    exit 0
}

# 检查并设置日志级别
set_log_level() {
    local config_file="$1"
    local log_level="$2"

    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    echo "正在修复日志级别设置为: $log_level..."
    # 如果 LogLevel 已存在并被注释，则去掉注释并更新级别
    if grep -Eq '^\s*#\s*LogLevel\s+' "$config_file"; then
        sed -i -E "s/^\s*#\s*LogLevel\s+.*/LogLevel $log_level/" "$config_file"
        echo "已去掉注释并更新 LogLevel 设置为: $log_level"
    elif grep -Eq '^\s*LogLevel\s+' "$config_file"; then
        # 如果 LogLevel 已存在且未被注释，直接更新
        sed -i -E "s/^\s*LogLevel\s+.*/LogLevel $log_level/" "$config_file"
        echo "已更新 LogLevel 设置为: $log_level"
    else
        # 如果未配置 LogLevel，新增一行
        echo "LogLevel $log_level" >> "$config_file"
        echo "已新增 LogLevel 设置为: $log_level"
    fi

    echo "正在重新加载 sshd 服务以应用配置更改..."
    systemctl restart sshd
    if [[ $? -eq 0 ]]; then
        echo "sshd 服务已成功重新加载，修复完成。"
    else
        echo "错误: sshd 服务重新加载失败。请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."
    local test_file="/tmp/sshd_config.test"
    cp "$CONFIG_FILE" "$test_file"

    echo "模拟错误日志级别配置..."
    echo "#LogLevel DEBUG" >> "$test_file"

    set_log_level "$test_file" "$DEFAULT_LEVEL"

    local current_level=$(grep -Ei '^\s*LogLevel\s+' "$test_file" | tail -n 1 | awk '{print $2}' | tr -d '[:space:]')
    if [[ "$current_level" == "$DEFAULT_LEVEL" ]]; then
        echo "自测成功: 日志级别已正确修复为 $DEFAULT_LEVEL"
    else
        echo "自测失败: 修复后的日志级别为 $current_level，应为 $DEFAULT_LEVEL"
        exit 1
    fi

    rm -f "$test_file"
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        -l|--level)
            DEFAULT_LEVEL=$(echo "$2" | tr '[:lower:]' '[:upper:]')
            shift 2 ;;
        --self-test)
            self_test
            exit 0 ;;
        -\?|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 执行日志级别修复
set_log_level "$CONFIG_FILE" "$DEFAULT_LEVEL"


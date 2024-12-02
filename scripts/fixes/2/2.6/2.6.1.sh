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
# Description: Security Baseline fix Script for 2.6.1
#
# #######################################################################################
# 启用 haveged 服务以增强系统熵池
#
# 功能说明：
# - 检查并安装 haveged 服务。
# - 启动 haveged 服务并设置为开机自启。
# - 提供自测功能，空接口，直接返回成功。

# 检查并安装 haveged 服务
install_haveged() {
    if ! systemctl list-unit-files | grep -q '^haveged\.service'; then
        echo "haveged 服务未安装，正在安装..."
        if command -v yum &>/dev/null; then
            yum install -y haveged
        elif command -v dnf &>/dev/null; then
            dnf install -y haveged
        elif command -v apt-get &>/dev/null; then
            apt-get install -y haveged
        else
            echo "错误: 未找到有效的包管理器 (yum/dnf/apt-get)。"
            exit 1
        fi

        # 检查安装是否成功
        if ! systemctl list-unit-files | grep -q '^haveged\.service'; then
            echo "错误: 安装 haveged 服务失败，请检查软件源配置。"
            exit 1
        fi
        echo "haveged 服务已成功安装。"
    else
        echo "haveged 服务已安装。"
    fi
}

# 启动并启用 haveged 服务
start_haveged() {
    echo "正在启动 haveged 服务..."
    systemctl start haveged
    if [ "$(systemctl is-active haveged)" == "active" ]; then
        echo "haveged 服务已成功启动。"
    else
        echo "错误: 无法启动 haveged 服务，请检查服务配置或系统日志。"
        exit 1
    fi

    echo "正在设置 haveged 服务为开机自启..."
    systemctl enable haveged
    echo "haveged 服务已设置为开机自启。"
}

# 空接口的自测功能
self_test() {
    echo "自测接口保留，直接返回成功。"
    return 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            echo "使用方法: $0 [--self-test]"
            exit 1
            ;;
    esac
done

# 主修复逻辑
install_haveged
start_haveged

echo "haveged 服务已成功启用并设置为开机自启。"
exit 0


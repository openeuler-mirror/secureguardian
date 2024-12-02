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
# Description: Security Baseline Check Script for 2.5.2
#
# #######################################################################################
#
# 启用 AIDE 入侵检测并完成必要的配置和初始化
# 功能说明：
# - 自动检测并安装 `aide` 软件包。
# - 配置默认的监控路径到 `/etc/aide.conf`。
# - 生成 AIDE 的基准数据库。
# - 提供自测功能，通过模拟环境验证脚本逻辑。
#
# #######################################################################################

# 检查是否已安装 aide 软件包
install_aide() {
    if ! command -v aide &>/dev/null; then
        echo "AIDE 未安装，正在安装..."
        if command -v yum &>/dev/null; then
            yum install -y aide
        elif command -v dnf &>/dev/null; then
            dnf install -y aide
        else
            echo "错误: 未找到有效的包管理器 (yum/dnf)。"
            exit 1
        fi

        # 检查安装是否成功
        if ! command -v aide &>/dev/null; then
            echo "错误: 安装 AIDE 失败，请检查网络连接或软件源配置。"
            exit 1
        fi
        echo "AIDE 已成功安装。"
    else
        echo "AIDE 已安装。"
    fi
}

# 配置默认的监控路径
configure_aide() {
    local aide_conf="/etc/aide.conf"
    local default_dirs=("/boot" "/bin" "/lib" "/lib64")

    if [ ! -f "$aide_conf" ]; then
        echo "错误: 配置文件 $aide_conf 不存在。请手动检查。"
        exit 1
    fi

    echo "正在配置 AIDE 的监控路径..."
    for dir in "${default_dirs[@]}"; do
        if ! grep -qE "^$dir\s+NORMAL" "$aide_conf"; then
            echo "$dir   NORMAL" >>"$aide_conf"
            echo "已添加监控路径: $dir"
        else
            echo "路径 $dir 已配置为监控目录，无需修改。"
        fi
    done
    echo "AIDE 配置已更新。"
}

# 初始化基准数据库
initialize_aide_db() {
    local aide_db="/var/lib/aide/aide.db.gz"
    local new_aide_db="/var/lib/aide/aide.db.new.gz"

    echo "正在初始化 AIDE 的基准数据库..."
    aide --init
    if [ -f "$new_aide_db" ]; then
        mv "$new_aide_db" "$aide_db"
        echo "基准数据库已初始化并保存到 $aide_db"
    else
        echo "错误: 初始化基准数据库失败，请检查 AIDE 配置和日志。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟配置和初始化 AIDE 基准数据库..."
    local test_conf="/tmp/aide_test.conf"
    local test_db="/tmp/aide_test.db.gz"
    local new_test_db="/tmp/aide_test.db.new.gz"

    echo "正在创建模拟配置文件和目录..."
    echo "/tmp/testdir NORMAL" >"$test_conf"
    mkdir -p /tmp/testdir

    echo "模拟初始化基准数据库..."
    aide --init -c "$test_conf" > /dev/null 2>&1
    if [ -f "$new_test_db" ]; then
        mv "$new_test_db" "$test_db"
        echo "自测成功: 模拟基准数据库已正确初始化。"
        rm -f "$test_conf" "$test_db"
        rm -rf /tmp/testdir
    else
        echo "自测失败: 无法初始化基准数据库，请检查。"
        exit 1
    fi
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
install_aide
configure_aide
initialize_aide_db

echo "AIDE 入侵检测已成功启用并完成配置。"
exit 0


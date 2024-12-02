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
# Description: Security Baseline Check Script for 3.1.1
#
# #######################################################################################
# 禁用不常见的网络服务模块（如 SCTP 和 TIPC）
#
# 功能说明：
# - 确保指定的模块（SCTP/TIPC）被正确禁用。
# - 在 /etc/modprobe.d 目录下创建配置文件。
# - 提供自测功能，验证脚本逻辑。

CONFIG_FILE="/etc/modprobe.d/disable-uncommon-modules.conf"

# 禁用指定模块
disable_module() {
    local module=$1
    echo "正在禁用模块 $module..."

    if grep -q "install $module /bin/true" "$CONFIG_FILE" 2>/dev/null; then
        echo "模块 $module 已在 $CONFIG_FILE 中禁用，无需重复操作。"
    else
        echo "install $module /bin/true" >>"$CONFIG_FILE"
        echo "模块 $module 已添加到 $CONFIG_FILE。"
    fi

    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    echo "配置文件权限已设置为 600，属主为 root。"
}

# 检查模块是否禁用
check_module_disabled() {
    local module=$1
    local output
    output=$(modprobe -n -v "$module" 2>&1)

    if [[ $output == *"install /bin/true"* ]]; then
        echo "模块 $module 已被正确禁用。"
        return 0
    else
        echo "模块 $module 未被禁用。详细输出：$output"
        return 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟禁用 SCTP 和 TIPC 模块..."
    local test_file="/tmp/disable-uncommon-modules.test.conf"

    echo "创建临时配置文件: $test_file"
    CONFIG_FILE="$test_file"

    disable_module "sctp"
    disable_module "tipc"

    # 验证是否禁用
    local failure=0
    for module in sctp tipc; do
        check_module_disabled "$module" || failure=1
    done

    # 清理临时文件
    rm -f "$test_file"

    if [ $failure -eq 0 ]; then
        echo "自测成功: 模块 SCTP 和 TIPC 已成功禁用。"
    else
        echo "自测失败: 无法正确禁用模块。"
        exit 1
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--module)
            module="$2"
            shift 2
            ;;
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "用法: $0 [-m|--module 模块名] [--self-test]"
            echo "示例: $0 --module sctp"
            exit 1
            ;;
    esac
done

# 设置默认模块列表
if [[ -z $module ]]; then
    module_list=("sctp" "tipc")
else
    module_list=("$module")
fi

# 修复逻辑
for mod in "${module_list[@]}"; do
    disable_module "$mod"
    check_module_disabled "$mod" || {
        echo "错误: 无法禁用模块 $mod。"
        exit 1
    }
done

echo "所有模块已成功禁用。"
exit 0


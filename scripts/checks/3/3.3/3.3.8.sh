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
# Description: Security Baseline Check Script for 3.3.8
#
# #######################################################################################

# 默认配置文件路径
CONFIG_FILE="/etc/sysconfig/sshd"
# 允许的例外列表，默认为空
ALLOWED_POLICIES=()

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [-a allowed_policies] [-?]"
    echo "选项:"
    echo "  -c, --config       指定SSH sysconfig 文件的路径，默认为/etc/sysconfig/sshd"
    echo "  -a, --allowed      指定允许的CRYPTO_POLICY设置，用逗号分隔"
    echo "  -?, --help         显示帮助信息"
    exit 0
}

# 检查加密算法覆盖策略是否被禁用或符合例外
check_crypto_policy_disabled() {
    local config_file=$1
    local allowed_policies=("${!2}")

    # 检查CRYPTO_POLICY字段是否为空或被注释掉
    local policy=$(grep "^\s*CRYPTO_POLICY=" "$config_file" | cut -d '=' -f2- | tr -d '"' | xargs)

    if [[ -z "$policy" || "$policy" =~ ^\s*# ]]; then
        echo "检测成功: 加密算法覆盖策略未配置。"
        return 0
    elif [[ " ${allowed_policies[*]} " =~ " $policy " ]]; then
        echo "检测成功: 加密算法覆盖策略配置为允许的例外 '$policy'。"
        return 0
    else
        echo "检测失败: 加密算法覆盖策略已配置且不符合任何允许的例外。当前设置为: $policy"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2 ;;
        -a|--allowed)
            IFS=',' read -r -a ALLOWED_POLICIES <<< "$2"
            shift 2 ;;
        -\?|--help)
            usage ;;
        *)
            echo "未知选项: $1"
            usage ;;
    esac
done

# 执行加密算法覆盖策略检查
if check_crypto_policy_disabled "$CONFIG_FILE" ALLOWED_POLICIES[@]; then
    exit 0
else
    exit 1
fi


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
# Description: Security Baseline Check Script for 3.2.6
#
# #######################################################################################

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-c <chain_name> -p <policy>]+"
    echo "示例：$0 -c INPUT -p DROP -c OUTPUT -p DROP -c FORWARD -p DROP"
    echo "不带选项时默认检查 INPUT、OUTPUT、FORWARD 链的策略为 DROP。"
}

# 函数：检查iptables链的默认策略
check_iptables_policy() {
    local chain_name=$1
    local expected_policy=$2
    # 使用进程替换而不是管道
    local policy=$(iptables -L $chain_name -n --line-numbers | grep "^Chain $chain_name" | awk '{print $4}' | tr -d '()')
    
    if [[ "$policy" == "$expected_policy" ]]; then
        echo "$chain_name 链的默认策略为 $expected_policy，符合预期。"
        return 0
    else
        echo "检测失败: $chain_name 链的默认策略为 $policy，与预期 $expected_policy 状态不符。"
        return 1
    fi
}

# 解析命令行参数
declare -A chains
chain_name=""
policy=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--chain)
            chain_name="$2"
            shift; shift
            ;;
        -p|--policy)
            if [[ -n "$chain_name" ]]; then
                chains["$chain_name"]="$2"
                chain_name=""
            else
                echo "错误：策略设置前未定义链。"
                show_usage
                exit 1
            fi
            shift; shift
            ;;
        /?|--help)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# 如果没有指定任何链和策略，使用默认值
if [ ${#chains[@]} -eq 0 ]; then
    chains["INPUT"]="DROP"
    chains["OUTPUT"]="DROP"
    chains["FORWARD"]="DROP"
fi

# 检查链的策略
overall_success=0
for chain in "${!chains[@]}"; do
    check_iptables_policy "$chain" "${chains[$chain]}" || overall_success=1
done

# 根据检查结果退出
if [[ $overall_success -eq 0 ]]; then
    echo "所有检查通过。"
    exit 0
else
    echo "至少一个检查未通过。"
    exit 1
fi



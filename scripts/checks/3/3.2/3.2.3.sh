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
# Description: Security Baseline Check Script for 3.2.3
#
# #######################################################################################

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-i <interface> -z <zone>]+"
    echo "示例：$0 -i eth0 -z public -i eth1 -z internal"
    echo "不带选项时，默认检查 eth0 是否在 public 区域。"
}

# 默认接口与区域
declare -A default_bindings=(
    [eth0]="public"
)

# 函数：检查接口是否绑定到正确区域
check_interface_zone_binding() {
    local interface=$1
    local expected_zone=$2
    local actual_zone=$(firewall-cmd --get-zone-of-interface=$interface)

    if [[ "$actual_zone" == "$expected_zone" ]]; then
        echo "接口 $interface 正确绑定到区域 $expected_zone。"
        return 0
    else
        echo "检测失败: 接口 $interface 绑定到区域 <$actual_zone>，预期应为 $expected_zone。"
        return 1
    fi
}

# 解析命令行参数
declare -A bindings
interface=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interface)
            interface="$2"
            shift; shift
            ;;
        -z|--zone)
            if [[ -n "$interface" ]]; then
                bindings["$interface"]="$2"
                interface=""
            else
                echo "错误：未指定接口。"
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

# 如果没有指定任何接口和区域，使用默认值
if [ ${#bindings[@]} -eq 0 ]; then
    for key in "${!default_bindings[@]}"; do
        bindings[$key]=${default_bindings[$key]}
    done
fi

# 检查接口和区域的绑定
overall_success=0
for interface in "${!bindings[@]}"; do
    check_interface_zone_binding "$interface" "${bindings[$interface]}" || overall_success=1
done

# 根据检查结果退出
if [[ $overall_success -eq 0 ]]; then
    echo "所有接口的区域绑定检查通过。"
    exit 0
else
    echo "至少有一个接口的区域绑定检查未通过。"
    exit 1
fi


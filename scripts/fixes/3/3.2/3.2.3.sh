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
#!/bin/bash

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-i <interface> -z <zone>]..."
    echo "示例：$0 -i eth0 -z public -i eth1 -z internal"
    echo "必须指定至少一个接口和区域进行绑定。"
}

# 函数：解除接口的所有绑定
remove_interface_from_all_zones() {
    local interface=$1
    zones=$(firewall-cmd --get-zone-of-interface=$interface)
    for zone in $zones; do
        echo "正在将接口 $interface 从区域 $zone 移除..."
        firewall-cmd --zone=$zone --remove-interface=$interface
    done
}

# 函数：将接口绑定到指定区域
bind_interface_to_zone() {
    local interface=$1
    local zone=$2
    echo "正在将接口 $interface 绑定到区域 $zone..."
    firewall-cmd --zone=$zone --add-interface=$interface
}

# 函数：持久化配置
persist_firewall_config() {
    echo "正在将当前防火墙配置持久化到配置文件中..."
    firewall-cmd --runtime-to-permanent
    firewall-cmd --reload
}

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
            echo "无效选项: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 检查是否指定了参数
if [[ ${#bindings[@]} -eq 0 ]]; then
    echo "错误：未指定任何接口和区域，请使用正确的参数。"
    show_usage
    exit 1
fi

# 检查并修复接口绑定
overall_success=0
echo "开始处理绑定配置："
for interface in "${!bindings[@]}"; do
    expected_zone="${bindings[$interface]}"
    echo "检查接口 $interface 是否绑定到区域 $expected_zone"

    # 1. 解除接口的所有绑定
    remove_interface_from_all_zones "$interface"

    # 2. 将接口绑定到指定区域
    bind_interface_to_zone "$interface" "$expected_zone"

    # 3. 持久化防火墙配置
    persist_firewall_config

    # 4. 检查接口绑定是否正确
    check_interface_zone_binding "$interface" "$expected_zone" || overall_success=1
done

# 根据检查结果退出
if [[ $overall_success -eq 0 ]]; then
    echo "修复完成：所有指定的接口已绑定到正确的区域，并持久化配置。"
    exit 0
else
    echo "修复失败：至少有一个接口的区域绑定未通过验证。"
    exit 1
fi


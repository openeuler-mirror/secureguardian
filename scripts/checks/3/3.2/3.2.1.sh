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
# Description: Security Baseline Check Script for 3.2.1
#
# #######################################################################################

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-s <service_name> -t <expected_status>]+"
    echo "示例：$0 -s firewalld -t active -s iptables -t inactive"
    echo "      $0 -s iptables -t active -s firewalld -t inactive"
    echo "不带选项时默认检查 firewalld 为 active，iptables 和 nftables 为 inactive。"
}

# 函数：检查服务状态
check_service_status() {
    local service_name=$1
    local expected_status=$2
    local status_output=$(systemctl is-active $service_name 2>&1 )

    if [[ $expected_status == $status_output ]]; then
        echo "$service_name 服务状态为 $expected_status，符合预期。"
        return 0
    else
        echo "检测失败: $service_name 的状态为 ${status_output}, 与预期 $expected_status 状态不符。"
        return 1
    fi
}

# 默认服务和状态
declare -A default_services=(
    [firewalld]="active"
    [iptables]="inactive"
    [nftables]="inactive"
)

# 解析命令行参数
declare -A services
service_name=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service)
            service_name="$2"
            shift; shift
            ;;
        -t|--status)
            if [[ -n "$service_name" ]]; then
                services["$service_name"]="$2"
                service_name=""
            else
                echo "错误：状态设置前未定义服务。"
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

# 如果没有指定任何服务，使用默认值
if [ ${#services[@]} -eq 0 ]; then
    for key in "${!default_services[@]}"; do
        services["$key"]="${default_services[$key]}"
    done
fi

# 检查服务状态
overall_success=0
for service in "${!services[@]}"; do
    check_service_status "$service" "${services[$service]}" || overall_success=1
done

# 根据检查结果退出
if [[ $overall_success -eq 0 ]]; then
    echo "检查成功:所有检查通过。"
    exit 0
else
    echo "检查失败:至少一个检查未通过。"
    exit 1
fi


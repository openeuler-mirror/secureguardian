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
# Description: Security Baseline fix Script for 3.1.2
#
# #######################################################################################
#
# 禁用无线网络（WIFI 和 WWAN）功能
#
# 功能说明：
# - 强制禁用无线网络（WIFI 和 WWAN）。
# - 确保禁用配置永久生效。
# - 提供自测功能，空接口，直接返回成功。

# 禁用无线网络
disable_wireless() {
    echo "正在禁用无线网络..."
    nmcli radio all off

    if [ $? -eq 0 ]; then
        echo "无线网络已成功禁用，并确保配置永久生效。"
    else
        echo "错误: 无法禁用无线网络，请手动检查。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "自测接口保留，直接返回成功。"
    return 0
}

# 参数解析
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
disable_wireless
exit 0


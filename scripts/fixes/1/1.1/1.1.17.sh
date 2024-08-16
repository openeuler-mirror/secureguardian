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
# Description: Security Baseline Fix Script for 1.1.17
#
# #######################################################################################

# 修复函数，禁用USB存储设备
fix_usb_storage_disabled() {
    local conf_file="/etc/modprobe.d/disable-usb-storage.conf"

    # 创建配置文件并添加禁用USB存储设备的指令
    echo "install usb-storage /bin/true" > "$conf_file"

    # 设置配置文件的属主和权限
    chown root:root "$conf_file"
    chmod 600 "$conf_file"

    # 确认配置已生效
    local usb_storage_status=$(modprobe -n -v usb-storage)
    if [[ "$usb_storage_status" == *"install /bin/true"* ]]; then
        echo "USB存储设备已成功禁用。"
        return 0
    else
        echo "修复失败：无法禁用USB存储设备。"
        return 1
    fi
}

# 自测部分
self_test() {
    local test_conf_file="/etc/modprobe.d/test-disable-usb-storage.conf"

    echo "自测：检测禁用USB存储设备"

    # 创建临时配置文件并添加禁用USB存储设备的指令
    echo "install usb-storage /bin/true" > "$test_conf_file"

    # 设置配置文件的属主和权限
    chown root:root "$test_conf_file"
    chmod 600 "$test_conf_file"

    # 检查临时配置是否生效
    local usb_storage_status=$(modprobe -n -v usb-storage)
    if [[ "$usb_storage_status" == *"install /bin/true"* ]]; then
        echo "自测成功：USB存储设备已被禁用"
        # 删除临时配置文件以还原设置
        rm -f "$test_conf_file"
        return 0
    else
        echo "自测失败：USB存储设备未被禁用"
        # 删除临时配置文件以还原设置
        rm -f "$test_conf_file"
        return 1
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [--self-test]"
    echo "选项:"
    echo "  --self-test                进行自测"
    echo "  /?                         显示此帮助信息"
}

# 检查命令行参数
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
elif [[ "$1" == "/?" ]]; then
    show_usage
    exit 0
else
    # 执行修复
    fix_usb_storage_disabled
    exit $?
fi


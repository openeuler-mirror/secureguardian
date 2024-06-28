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
# Description: Security Baseline Fix Script for 1.1.8
#
# #######################################################################################

# 使用方法提示
usage() {
    echo "使用方法: $0 --self-test 或 $0 [挂载点路径] [设备路径]"
    echo "例如: $0 /root/readonly /dev/sda1"
    echo "或: $0 --self-test"
}

# 检查并修复只读挂载
fix_readonly_mount() {
    local mount_point="$1"
    local device_path="$2"

    # 检查挂载点是否已经以只读方式挂载
    if mount | grep "$mount_point" | grep -q "\<ro\>"; then
        echo "指定的分区 $mount_point 已正确以只读方式挂载。"
        exit 0
    else
        echo "指定的分区 $mount_point 未以只读方式挂载或未挂载，正在尝试修复..."
        umount "$mount_point" 2>/dev/null
        mount -o ro "$device_path" "$mount_point"
        if mount | grep "$mount_point" | grep -q "\<ro\>"; then
            echo "已成功以只读方式挂载 $mount_point。"
            exit 0
        else
            echo "尝试以只读方式挂载 $mount_point 失败。"
            exit 1
        fi
    fi
}

# 自测功能
self_test() {
    local test_mount_point="/tmp/readonly_test_mount"
    local test_device="/dev/loop0"
    local test_image="/tmp/readonly_test.img"

    # 创建临时环境
    dd if=/dev/zero of=$test_image bs=1M count=10 &>/dev/null
    losetup $test_device $test_image
    mkfs.ext4 $test_device &>/dev/null
    mkdir -p $test_mount_point

    # 尝试挂载
    fix_readonly_mount "$test_mount_point" "$test_device"

    # 清理环境
    umount $test_mount_point
    losetup -d $test_device
    rm -rf $test_mount_point $test_image
}

# 主执行逻辑
if [ "$#" -eq 0 ]; then
    usage
elif [ "$1" == "--self-test" ]; then
    self_test
else
    fix_readonly_mount "$1" "$2"
fi

exit $?


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
# Description: Security Baseline Fix Script for 1.1.9
#
# #######################################################################################

# 定义默认挂载点用于自测
test_mount_point="/tmp/test_nodev_mount"
test_device="/dev/loop0"
test_image="/tmp/test_nodev.img"

# 使用方法说明
usage() {
    echo "使用方法: $0 [--self-test]"
    echo "例如: $0 --self-test"
    exit 0
}

# 检测并修复未以nodev方式挂载的分区
fix_nodev_mounts() {
    local exclude_dirs=(
        "/dev"
        "/dev/pts"
        "/"
        "/sys/fs/selinux"
        "/proc/sys/fs/binfmt_misc"
        "/dev/hugepages"
        "/boot"
        "/var/lib/nfs/rpc_pipefs"
        "/boot/efi"
        "/home"
    )
    local error_found=0

    while IFS= read -r line; do
        local mount_point=$(echo "$line" | awk '{print $3}')
        if [[ ! " ${exclude_dirs[*]} " =~ " ${mount_point} " ]]; then
            if echo "$line" | grep -qv "nodev"; then
                echo "存在未以nodev方式挂载的分区: $mount_point"
                echo "尝试重新挂载为nodev..."
                umount "$mount_point"
                mount -o remount,nodev "$mount_point"
                if mount | grep "$mount_point" | grep -q "nodev"; then
                    echo "修复成功: $mount_point 已重新挂载为nodev。"
                else
                    echo "修复失败: 无法重新挂载 $mount_point 为nodev。"
                    error_found=1
                fi
            fi
        fi
    done < <(mount)
    
    if [[ $error_found -eq 0 ]]; then
        echo "所有分区（除默认排除目录外）均已正确以nodev方式挂载或已修复。"
        exit 0
    else
        echo "存在挂载点未能修复为nodev。"
        exit 1
    fi
}

# 创建和准备自测环境
prepare_self_test() {
    dd if=/dev/zero of="$test_image" bs=1M count=1 &>/dev/null
    losetup "$test_device" "$test_image"
    mkfs.ext4 "$test_device" &>/dev/null
    mkdir -p "$test_mount_point"
    mount -o rw "$test_device" "$test_mount_point"
    echo "自测环境已创建并挂载。"
}

# 清理自测环境
cleanup_self_test() {
    umount "$test_mount_point"
    losetup -d "$test_device"
    rm -rf "$test_mount_point" "$test_image"
    echo "自测环境已清理。"
}

# 执行自测
self_test() {
    prepare_self_test
    echo "开始自测挂载点 $test_mount_point 是否可以正确设置为nodev..."
    mount -o remount,nodev "$test_mount_point"
    if mount | grep "$test_mount_point" | grep -q "nodev"; then
        echo "自测成功：$test_mount_point 已正确设置为nodev。"
        cleanup_self_test
        exit 0
    else
        echo "自测失败：$test_mount_point 未设置为nodev。"
        cleanup_self_test
        exit 1
    fi
}

# 主执行逻辑
case "$1" in
    --self-test)
        self_test
        ;;
    --help)
        usage
        ;;
    *)
        fix_nodev_mounts
        ;;
esac

exit $?

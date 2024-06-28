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
# Description: Security Baseline Fix Script for 1.1.10
#
# #######################################################################################

# 使用方法说明
usage() {
    echo "使用方法: $0 [--self-test | 挂载点路径1 挂载点路径2 ...]"
    echo "例如: $0 --self-test"
    echo "或: $0 /root/noexec /var/noexec"
    exit 1
}

# 检测并尝试修复未以noexec方式挂载的分区
fix_noexec_mounts() {
    local mount_point
    local noexec_missing=0
    local mount_options

    for mount_point in "$@"; do
        echo "检查挂载点: $mount_point"
        # 使用awk分析每个挂载点的挂载选项
        mount_options=$(mount | awk -v mp="$mount_point" '$3 == mp {print $6}')

        if [ -n "$mount_options" ]; then
            echo "挂载点 $mount_point 存在，正在检查noexec设置..."
            if [[ "$mount_options" != *noexec* ]]; then
                echo "分区 ${mount_point} 未以noexec方式挂载。尝试修复中..."
                umount "$mount_point"
                if mount -o remount,noexec "$mount_point"; then
                    echo "已成功以noexec方式重新挂载 $mount_point。"
                else
                    echo "尝试以noexec方式重新挂载 $mount_point 失败。"
                    noexec_missing=1
                fi
            else
                echo "分区 ${mount_point} 已正确以noexec方式挂载。"
            fi
        else
            echo "分区 ${mount_point} 不存在或无法读取挂载选项。"
            noexec_missing=1
        fi
    done

    if [ $noexec_missing -eq 0 ]; then
        echo "所有指定的分区均已正确以noexec方式挂载或已修复。"
        exit 0
    else
        echo "至少一个指定分区未以noexec方式挂载或分区不存在。"
        exit 1
    fi
}

# 自测环境
self_test() {
    local test_mount_point="/tmp/test_noexec_mount"
    mkdir -p "$test_mount_point"
    mount -t tmpfs tmpfs "$test_mount_point" -o rw
    echo "自测环境已创建并挂载。开始测试noexec挂载设置..."

    fix_noexec_mounts "$test_mount_point"

    # 清理环境
    umount "$test_mount_point"
    rmdir "$test_mount_point"
    echo "自测环境已清理。"
}

# 执行逻辑
if [ "$1" == "--self-test" ]; then
    self_test
else
    fix_noexec_mounts "$@"
fi


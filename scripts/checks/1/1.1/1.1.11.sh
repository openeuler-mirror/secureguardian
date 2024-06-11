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
# Description: Security Baseline Check Script for 1.1.11
#
# #######################################################################################

# 检测可移动设备分区是否已以noexec和nodev方式挂载
check_removable_dev_mount() {
    local has_issue=0

    # 使用lsblk命令获取所有可移动设备的列表
    mapfile -t removable_devices < <(lsblk -dno NAME,RM | awk '$2=="1"{print $1}')

    # 遍历可移动设备列表
    for dev in "${removable_devices[@]}"; do
        # 检查设备是否挂载
        if mountpoint=$(mount | grep "^/dev/$dev" | awk '{print $3}'); then
            # 检查挂载的设备是否未正确设置noexec和nodev
            if mount | grep "^/dev/$dev on $mountpoint " | grep -vqE 'noexec' || mount | grep "^/dev/$dev on $mountpoint " | grep -vqE 'nodev'; then
                echo "设备 /dev/$dev 挂载在 $mountpoint 未以noexec和nodev方式挂载："
                mount | grep "^/dev/$dev on $mountpoint "
                has_issue=1
            fi
        fi
    done

    # 根据检测结果返回
    if [ $has_issue -eq 1 ]; then
        return 1  # 存在至少一个问题，检测未通过
    else
        echo "所有可移动设备分区均已以noexec和nodev方式挂载。"
        return 0  # 所有检测均通过
    fi
}

# 调用检测函数并根据返回值决定输出
if check_removable_dev_mount; then
    #echo "检查通过。"
    exit 0
else
    #echo "至少一个指定分区未以noexec或nodev方式挂载。"
    exit 1
fi


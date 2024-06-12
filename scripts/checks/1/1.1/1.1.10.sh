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
# Description: Security Baseline Check Script for 1.1.10
#
# #######################################################################################

# 检测指定分区是否已以noexec方式挂载
# 使用方法: ./script_name [挂载点路径1] [挂载点路径2] ...
# 例如: ./script_name /mcm

check_noexec_mount() {
    local missing_mount=0
    local noexec_missing=0

    # 检查是否有参数传递给脚本
    if [ $# -eq 0 ]; then
        echo "未提供挂载点路径参数，不执行检查并假定检查通过。"
        return 0
    fi

    # 遍历所有传递给脚本的参数（挂载点路径）
    for mount_point in "$@"; do
        # 使用 mount 命令检查每个挂载点
        if mount | grep -q " on ${mount_point} "; then
            # 挂载点存在，检查是否以noexec方式挂载
            if ! mount | grep " on ${mount_point} " | grep -q "noexec"; then
                echo "分区 ${mount_point} 未以noexec方式挂载。"
                noexec_missing=1
            fi
        else
            echo "分区 ${mount_point} 不存在。"
            missing_mount=1
        fi
    done

    if [ $missing_mount -eq 1 ] || [ $noexec_missing -eq 1 ]; then
        echo "至少一个指定分区未以noexec方式挂载或分区不存在。"
        return 1
    else
        echo "所有指定的分区均已正确以noexec方式挂载。"
        return 0
    fi
}

# 调用检测函数并传递所有命令行参数
# 调用检测函数并根据返回值决定输出
if check_noexec_mount "$@"; then
  exit 0
else
  exit 1
fi

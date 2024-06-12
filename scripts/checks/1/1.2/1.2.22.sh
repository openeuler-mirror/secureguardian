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
# Description: Security Baseline Check Script for 1.2.22
#
# #######################################################################################

# 函数：检查NFS服务（nfs-server）是否已启用
check_nfs_service_enabled() {
    # 检查NFS服务是否已启用
    if systemctl is-enabled nfs-server &>/dev/null; then
        echo "NFS服务（nfs-server）已启用。如果不需要作为NFS服务器，请考虑禁用它。"
        return 1 # 如果服务已启用，则返回1
    else
        echo "NFS服务（nfs-server）已禁用或未安装。"
        return 0 # 如果服务已禁用或未安装，则返回0
    fi
}

# 调用函数
check_nfs_service_enabled

# 捕获函数返回值
exit $?

# 以此值退出脚本

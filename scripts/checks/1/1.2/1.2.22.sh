#!/bin/bash

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

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
# Description: Security Baseline Fix Script for 1.1.18
#
# #######################################################################################

# 修复函数，分区管理硬盘数据
fix_disk_partitioning() {
    echo "需要用户手工处理分区管理。请按照以下步骤操作："
    echo "1. 为每个需要单独挂载的目录创建分区（例如 /dev/sdb1）。"
    echo "2. 使用 mkfs.ext4 命令格式化新分区（例如 mkfs.ext4 /dev/sdb1）。"
    echo "3. 临时挂载新分区到一个临时目录（例如 mount /dev/sdb1 /mnt/temp）。"
    echo "4. 使用 rsync 命令将现有数据迁移到新分区（例如 rsync -av /home/ /mnt/temp/）。"
    echo "5. 更新 /etc/fstab 文件以确保系统重启后自动挂载新分区。"
    echo "6. 挂载新分区到目标目录（例如 mount /dev/sdb1 /home）。"
    echo "请确保在操作前备份所有重要数据。"
    echo ""
    echo "示例代码："
    echo "-----------------------------------------"
    echo "#!/bin/bash"
    echo "set -e"
    echo "read -p '请输入用于挂载 /home 的设备名（例如 /dev/sdb1）：' device"
    echo "mkfs.ext4 \$device"
    echo "mkdir -p /mnt/temp_mount_home"
    echo "mount \$device /mnt/temp_mount_home"
    echo "rsync -av /home/ /mnt/temp_mount_home/"
    echo "umount /mnt/temp_mount_home"
    echo "rmdir /mnt/temp_mount_home"
    echo "echo '\$device /home ext4 defaults 1 1' >> /etc/fstab"
    echo "mount \$device /home"
    echo "-----------------------------------------"
    return 0
}

# 自测部分
self_test() {
    echo "自测：分区管理硬盘数据"
    echo "提示：需要用户手工处理分区管理，参考示例代码进行操作。"
    return 0
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
    # 返回需要用户手工处理提示
    fix_disk_partitioning
    exit $?
fi


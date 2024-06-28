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
# Description: Security Baseline Fix Script for 1.1.7
#
# #######################################################################################

# 设置默认参数和初始化变量
initialize_and_set_defaults() {
    # 定义默认的文件系统列表
    local default_fs="cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat fat msdos nfs ceph fuse overlay xfs"

    # 根据传入参数确定要操作的文件系统列表
    if [ "$#" -gt 1 ]; then
        # 从命令行参数获取文件系统列表
        fs_list="${@:2}"
    else
        fs_list=$default_fs
    fi

    echo "文件系统列表已设置：$fs_list"
}

# 禁用非必需的文件系统
disable_filesystems() {
    local mounted_fs=$(awk '$1 !~ /^#/ && $1 != "none" {print $3}' /proc/mounts | sort -u)
    local fs disable_file="/etc/modprobe.d/custom_fs_disable.conf"

    # 创建或更新配置文件，并设置权限
    echo "正在创建或更新配置文件 $disable_file"
    touch $disable_file
    chmod 600 $disable_file

    # 添加禁用规则
    for fs in $fs_list; do
        if ! grep -qw "$fs" <<< "$mounted_fs"; then
            echo "install $fs /bin/true" >> $disable_file
            echo "已禁用 $fs，因为它当前没有被挂载。"
        else
            echo "$fs 当前已挂载，不会被禁用。"
        fi
    done
    echo "文件系统禁用操作完成。"
}

# 检查文件系统是否正确禁用的自测功能
self_test() {
    local fs
    local mounted_fs=$(awk '$1 !~ /^#/ && $1 != "none" {print $3}' /proc/mounts | sort -u)
    for fs in $fs_list; do
        echo "测试 $fs 是否正确禁用..."
        if grep -qw "$fs" <<< "$mounted_fs"; then
            echo "$fs 当前已挂载，不会被禁用。"
        elif modprobe -n -v $fs | grep -q "/bin/true"; then
            echo "$fs 已正确禁用。"
        else
            echo "错误：$fs 未被禁用。"
        fi
    done
}
# 主执行逻辑
case "$1" in
    --self-test)
        initialize_and_set_defaults "$@"
        self_test
        ;;
    --help)
        echo "使用方法：$0 [--self-test] [filesystems...]"
        echo "示例：$0 --self-test"
        echo "示例：$0 cramfs jffs2 hfs"
        ;;
    *)
        initialize_and_set_defaults "$@"
        disable_filesystems
        ;;
esac

exit $?


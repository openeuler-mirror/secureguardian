#!/bin/sh
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
# Description: Security Baseline Check Script for 1.1.12
#
# #######################################################################################

# 功能说明:
# 本脚本用于检测并修复未以nosuid方式挂载的分区。通过将分区以nosuid方式挂载，防止利用SUID/SGID文件进行权限提升，增强系统安全性。

# 定义检查并修复未以nosuid方式挂载分区的函数
fix_nosuid_mount() {
    local exceptions=()
    local specific_mount=""

    # 解析输入参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--exception)
                exceptions+=("$2")
                shift
                shift
                ;;
            -m|--mount)
                specific_mount="$2"
                shift
                shift
                ;;
            /?)
                show_usage
                return 0
                ;;
            *)
                echo "未知参数: $1"
                show_usage
                return 1
                ;;
        esac
    done

    local issue_found=0
    local mount_list

    if [[ -n "$specific_mount" ]]; then
        mount_list=$(mount | grep "$specific_mount")
    else
        mount_list=$(mount)
    fi

    while IFS= read -r line; do
        local mount_point=$(echo "$line" | awk '{print $3}')
        local fs_type=$(echo "$line" | awk '{print $5}')

        # 检查是否在例外列表中
        if [[ " ${exceptions[@]} " =~ " ${mount_point} " ]]; then
            continue
        fi

        # 排除特定的文件系统类型和特殊挂载点
        if [[ "$fs_type" == "autofs" ]] || [[ "$fs_type" == "hugetlbfs" ]] || [[ "$fs_type" == "rpc_pipefs" ]]; then
            continue
        fi

        # 排除根目录、/boot 和 /boot/efi 分区
        if [[ "$mount_point" == "/" ]] || [[ "$mount_point" == "/boot" ]] || [[ "$mount_point" == "/boot/efi" ]]; then
            continue
        fi

        # 检查未设置nosuid的挂载点
        if [[ "$line" != *"nosuid"* ]]; then
            echo "分区 $mount_point 未以nosuid方式挂载：$line"
            issue_found=1

            # 重新挂载分区以添加nosuid选项
            mount -o remount,nosuid "$mount_point"
            if [[ $? -ne 0 ]]; then
                echo "修复失败: 无法以nosuid方式重新挂载分区 $mount_point"
                return 1
            else
                echo "修复成功: 分区 $mount_point 已以nosuid方式重新挂载"
            fi
        fi
    done < <(echo "$mount_list")

    if [ $issue_found -eq 0 ]; then
        echo "所有关心的分区均已以nosuid方式挂载，或者特殊文件系统和挂载点已被正确排除。"
    fi

    return 0  # 所有检测均通过
}

# 自测部分
self_test() {
    # 创建测试环境
    mkdir -p /tmp/testdir
    mount --bind / /tmp/testdir

    echo "自测: 创建了一个测试挂载点 /tmp/testdir"

    # 运行修复函数
    fix_nosuid_mount -m /tmp/testdir

    # 检查自测结果
    mount | grep /tmp/testdir | grep nosuid > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "自测成功: 测试挂载点 /tmp/testdir 已以nosuid方式挂载"
        umount /tmp/testdir
        return 0
    else
        echo "自测失败: 测试挂载点 /tmp/testdir 未以nosuid方式挂载"
        umount /tmp/testdir
        return 1
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -e, --exception <挂载点>    指定例外的挂载点，可以多次使用"
    echo "  -m, --mount <挂载点>        只检测指定的挂载点"
    echo "  /?                          显示此帮助信息"
}

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
else
    # 调用修复函数并处理返回值
    fix_nosuid_mount "$@"
    exit $?
fi


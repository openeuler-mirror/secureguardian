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
#!/bin/bash

# 功能说明:
# 本脚本用于检查并修复系统中挂载的可移动设备分区，确保这些分区以noexec和nodev方式挂载。
# 使用此脚本可以提高系统的安全性，防止恶意软件从可移动设备上执行，减少攻击面。

# 定义全局变量和默认值
EXCLUDE_DEVICES=()
MOUNT_OPTIONS="nodev,noexec"

# 显示用法信息
show_usage() {
  echo "用法: $0 [-e 例外设备] [-o 挂载选项] [--self-test]"
  echo "  -e, --exclude    指定例外设备 (多个设备以逗号分隔)"
  echo "  -o, --options    指定挂载选项，默认: nodev,noexec"
  echo "  /?               显示此帮助信息"
  echo "  --self-test      运行自测程序"
}

# 自测部分（空接口）
self_test() {
  echo "自测: 该功能尚未实现"
  exit 0
}

# 解析命令行参数
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--exclude)
        IFS=',' read -r -a EXCLUDE_DEVICES <<< "$2"
        shift 2
        ;;
      -o|--options)
        MOUNT_OPTIONS="$2"
        shift 2
        ;;
      /?)
        show_usage
        exit 0
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "未知选项: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

# 检查并修复挂载选项
fix_removable_dev_mount() {
  local has_issue=0

  # 获取所有可移动设备列表
  mapfile -t removable_devices < <(lsblk -dno NAME,RM | awk '$2 == "1" {print $1}')

  # 遍历可移动设备列表
  for dev in "${removable_devices[@]}"; do
    # 跳过例外设备
    if [[ " ${EXCLUDE_DEVICES[@]} " =~ " ${dev} " ]]; then
      continue
    fi

    # 检查设备是否挂载
    if mountpoint=$(mount | grep "^/dev/$dev" | awk '{print $3}'); then
      if [[ -n "$mountpoint" ]]; then
        # 检查挂载的设备是否未正确设置noexec和nodev
        if ! mount | grep "^/dev/$dev on $mountpoint " | grep -qE "$MOUNT_OPTIONS"; then
          echo "设备 /dev/$dev 挂载在 $mountpoint 未以$MOUNT_OPTIONS方式挂载，正在重新挂载..."
          umount "$mountpoint"
          if mount -o "$MOUNT_OPTIONS" "/dev/$dev" "$mountpoint"; then
            echo "修复成功: 设备 /dev/$dev 已重新挂载为 $MOUNT_OPTIONS"
            echo "详细信息: /dev/$dev 挂载在 $mountpoint 已应用 $MOUNT_OPTIONS 选项"
          else
            echo "修复失败: 无法以 $MOUNT_OPTIONS 方式重新挂载设备 /dev/$dev"
            has_issue=1
          fi
        else
          echo "设备 /dev/$dev 挂载在 $mountpoint 已正确设置为 $MOUNT_OPTIONS"
        fi
      fi
    fi
  done

  return $has_issue
}

# 解析命令行参数
parse_args "$@"

# 调用修复函数并处理返回值
if fix_removable_dev_mount; then
  echo "所有可移动设备分区均已以$MOUNT_OPTIONS方式挂载。"
  exit 0
else
  echo "检测失败: 存在至少一个设备未以$MOUNT_OPTIONS方式挂载。"
  exit 1
fi


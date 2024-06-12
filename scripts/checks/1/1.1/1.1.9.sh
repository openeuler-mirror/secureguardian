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
# Description: Security Baseline Check Script for 1.1.9
#
# #######################################################################################

# 检测除了特定目录外，所有分区是否已以nodev方式挂载
check_nodev_mount() {
  # 定义需要排除的目录列表
  exclude_dirs=(
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

  # 获取当前所有挂载点，并检查是否设置了nodev
  while IFS= read -r line; do
    mount_point=$(echo "$line" | awk '{print $3}')
    if [[ ! " ${exclude_dirs[@]} " =~ " ${mount_point} " ]]; then
      if echo "$line" | grep -vq "nodev"; then
        echo "存在未以nodev方式挂载的分区: $mount_point"
        return 1
      fi
    fi
  done < <(mount)

  echo "所有分区（除默认排除目录外）均已正确以nodev方式挂载。"
  return 0
}

# 调用检测函数并根据返回值决定输出
if check_nodev_mount; then
  #echo "检查通过。"
  exit 0
else
  #echo "检查未通过。"
  exit 1
fi


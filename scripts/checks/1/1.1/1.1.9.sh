#!/bin/bash

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


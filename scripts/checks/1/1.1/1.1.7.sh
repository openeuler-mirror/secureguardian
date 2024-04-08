#!/bin/bash

# 如果提供了参数，则使用参数作为文件系统列表；否则，使用默认列表
fs_list="${1:-cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat fat msdos nfs ceph fuse overlay xfs}"

# 检测不需要的文件系统是否已被禁止挂载
check_fs_mount_disabled() {
  # 将字符串转换为数组
  IFS=' ' read -r -a fs_array <<< "$fs_list"
  
  for fs in "${fs_array[@]}"; do
    if ! modprobe -n -v $fs | grep -q 'install /bin/true'; then
      echo "文件系统 $fs 未被禁止挂载。"
      return 1
    fi
  done
  echo "所有不需要的文件系统均已被禁止挂载。"
  return 0
}

# 调用函数并处理返回值
if check_fs_mount_disabled; then
  #echo "检查通过。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过。"
  exit 1  # 检查未通过，脚本以失败退出
fi


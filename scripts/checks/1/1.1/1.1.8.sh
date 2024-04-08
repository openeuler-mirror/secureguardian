#!/bin/bash

# 检测指定分区是否已以只读方式挂载
# 使用方法: ./script_name [挂载点路径]
# 如果未提供挂载点路径参数，脚本不执行任何检查并直接返回检查通过

mount_point="${1}"

check_readonly_mounts() {
  # 检查是否提供了挂载点路径参数
  if [ -z "$mount_point" ]; then
    echo "未提供挂载点路径参数，不执行检查并假定检查通过。"
    return 0  # 直接返回检查通过
  fi

  # 使用 mount 命令查看指定目录是否为只读挂载
  if mount | grep "$mount_point" | grep "\<ro\>" > /dev/null; then
    echo "指定的分区 $mount_point 已正确以只读方式挂载。"
    return 0  # 检查通过
  else
    echo "指定的分区 $mount_point 未以只读方式挂载或未挂载。"
    return 1  # 检查未通过
  fi
}

# 调用检测函数
if check_readonly_mounts; then
  exit 0
else
  exit 1
fi


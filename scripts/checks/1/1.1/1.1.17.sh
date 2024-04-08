#!/bin/bash

# 检测是否禁用了USB存储
check_usb_storage_disabled() {
  local usb_storage_status=$(modprobe -n -v usb-storage)
  
  if [[ "$usb_storage_status" == *"install /bin/true"* ]]; then
    echo "USB存储已被禁用。"
    return 0  # 检查通过
  else
    echo "USB存储未被禁用。"
    return 1  # 检查未通过
  fi
}

# 调用检测函数
if check_usb_storage_disabled; then
  #echo "检查通过，不存在无属主或属组的文件或目录。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过。"
  exit 1  # 检查未通过，脚本以失败退出
fi

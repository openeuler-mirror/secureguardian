#!/bin/bash

# 设置默认的GRUB配置文件和用户配置文件路径
grub_cfg_paths=("/boot/efi/EFI/openEuler/grub.cfg" "/boot/grub2/grub.cfg")
user_cfg_paths=("/boot/efi/EFI/openEuler/user.cfg" "/boot/grub2/user.cfg")

# 如果通过脚本参数提供了GRUB配置文件路径，则使用提供的路径
if [ ! -z "$1" ]; then
  grub_cfg_paths=($1)
fi

# 如果通过脚本参数提供了用户配置文件路径，则使用提供的路径
if [ ! -z "$2" ]; then
  user_cfg_paths=($2)
fi

# 函数：检查GRUB是否设置了口令保护
check_grub_password_protection() {
  local found=0

  # 检查GRUB配置文件中是否存在password_pbkdf2配置
  for cfg_path in "${grub_cfg_paths[@]}"; do
    if [ -f "$cfg_path" ] && grep -q "password_pbkdf2" "$cfg_path"; then
      echo "检测通过：已在 $cfg_path 中配置GRUB口令保护。"
      found=1
      break
    fi
  done

  # 如果在grub.cfg中未找到password_pbkdf2配置，则检查user.cfg
  if [ $found -eq 0 ]; then
    for user_cfg in "${user_cfg_paths[@]}"; do
      if [ -f "$user_cfg" ] && grep -q "GRUB2_PASSWORD" "$user_cfg"; then
        echo "检测通过：已在 $user_cfg 中配置GRUB口令保护。"
        found=1
        break
      fi
    done
  fi

  # 根据检查结果确定脚本的退出状态
  if [ $found -eq 0 ]; then
    echo "检测失败：未找到GRUB口令保护的配置。"
    return 1  # 检查未通过
  fi
}

# 主函数
main() {
  check_grub_password_protection
  if [ $? -ne 0 ]; then
    exit 1  # 存在配置不符合要求
  else
    exit 0  # 所有检查均通过
  fi
}

main "$@"


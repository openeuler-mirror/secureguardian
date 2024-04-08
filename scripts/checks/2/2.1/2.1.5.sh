#!/bin/bash

# 定义预期的文件权限
declare -A expected_permissions=(
  ["/etc/passwd"]="0644"
  ["/etc/shadow"]="0000"
  ["/etc/group"]="0644"
  ["/etc/gshadow"]="0000"
  ["/etc/passwd-"]="0644"
  ["/etc/shadow-"]="0000"
  ["/etc/group-"]="0644"
  ["/etc/gshadow-"]="0000"
)

# 检查文件权限函数
check_file_permissions() {
  local file=$1
  local expected_perm=$2
  local actual_perm
  local owner_group

  # 检查文件是否存在
  if [[ ! -e "$file" ]]; then
    echo "检测失败: 文件 $file 不存在"
    return 1
  fi

  # 获取文件的实际权限和属主/属组
  actual_perm=$(stat -c "%a" "$file" | awk '{printf "%04d\n", $0}')
  owner_group=$(stat -c "%U:%G" "$file")

  # 检查属主和属组是否为root:root
  if [[ "$owner_group" != "root:root" ]]; then
    echo "检测失败: $file 的属主或属组不是 root:root。"
    return 1
  fi

  # 检查文件权限
  if [[ "$actual_perm" != "$expected_perm" ]]; then
    echo "检测失败: $file 的权限为 $actual_perm, 预期为 $expected_perm。"
    return 1
  fi

  return 0
}

# 主逻辑
all_checks_passed=true
for file in "${!expected_permissions[@]}"; do
  if ! check_file_permissions "$file" "${expected_permissions[$file]}"; then
    all_checks_passed=false
  fi
done

if $all_checks_passed; then
  echo "检测成功:所有文件权限均符合预期。"
  exit 0
else
  exit 1
fi


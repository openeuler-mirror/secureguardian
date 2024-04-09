#!/bin/bash

# 检测口令加密是否避免使用了较弱的Hash算法
check_password_encryption_strength() {
  # 指定检查的文件
  local check_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
  local weak_algorithms=("md5" "sha1" "sha256") # 定义被认为是较弱的算法
  local issue_found=0

  for file in "${check_files[@]}"; do
    if [ -f "$file" ]; then

      # 遍历每一个被认为是较弱的算法
      for alg in "${weak_algorithms[@]}"; do
        if grep -q "pam_unix.so.*$alg" "$file"; then
          echo "检测失败：$file 使用了被认为较弱的 $alg Hash算法。"
          issue_found=1
          break # 找到一个较弱的算法就足够了，无需继续检查
        fi
      done

      # 如果没有发现使用较弱的算法，打印成功信息
      if [ $issue_found -eq 0 ]; then
        echo "$file 没有使用被认为较弱的Hash算法。"
      fi
    else
      echo "警告：$file 文件不存在。"
      issue_found=1
    fi
  done

  # 根据发现的问题数量确定脚本的退出状态
  if [ "$issue_found" -ne 0 ]; then
    echo "存在配置不符合要求的文件。"
    return 1  # 存在问题
  else
    echo "所有相关配置文件均未使用被认为较弱的Hash算法。"
    return 0  # 无问题
  fi
}

# 调用检测函数并根据返回值决定脚本退出状态
if check_password_encryption_strength; then
  exit 0  # 检查通过
else
  exit 1  # 检查未通过
fi


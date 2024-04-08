#!/bin/bash

# 定义检查可执行的隐藏文件的函数
check_executable_hidden_files() {
  # 使用find命令查找除了.bashrc、.bash_profile、.bash_logout以外的可执行的隐藏文件
  local file=$(find / -type f -name "\.*" ! -name ".bashrc" ! -name ".bash_profile" ! -name ".bash_logout" -perm /+x -print -quit 2>/dev/null)

  if [[ ! -z $file ]]; then
    echo "找到可执行的隐藏文件：$file"
    return 1  # 发现问题，返回false
  else
    echo "未找到除.bashrc、.bash_profile、.bash_logout以外的可执行的隐藏文件。"
    return 0  # 未发现问题，返回true
  fi
}

# 调用函数并处理返回值
if check_executable_hidden_files; then
  #echo "检查通过。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过，存在可执行的隐藏文件。"
  exit 1  # 检查未通过，脚本以失败退出
fi


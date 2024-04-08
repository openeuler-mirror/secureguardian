#!/bin/bash

# 定义需要检查的目录列表
declare -a directories=("/boot" "/tmp" "/home" "/var" "/usr")

# 检测是否正确地分区管理硬盘数据
check_disk_partitioning() {
    local issue_found=0

    for dir in "${directories[@]}"; do
        # 使用 df 命令检查每个目录是否被单独挂载
        if ! df | grep -q " ${dir}$"; then
            echo "目录 ${dir} 没有单独挂载分区。"
            issue_found=1
        fi
    done

    if [ "$issue_found" -eq 0 ]; then
        echo "所有建议的目录均已单独挂载分区。"
	return 0
    else
        echo "一些建议的目录未单独挂载分区，请检查。"
        return 1  # 检查未通过
    fi
}

# 调用检测函数
if check_disk_partitioning; then
  #echo "检查通过，不存在无属主或属组的文件或目录。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过。"
  exit 1  # 检查未通过，脚本以失败退出
fi


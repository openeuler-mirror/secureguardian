#!/bin/bash

# 函数: 检查crontab中配置的脚本是否仅属主可写
check_crontab_scripts() {
    # 从/etc/crontab中提取执行脚本路径
    local crontab_entries=$(awk '{for (i = 1; i <= NF; i++) if ($i ~ /^\//) print $i}' /etc/crontab)

    # 判断是否存在可执行路径
    if [ -z "$crontab_entries" ]; then
        echo "未发现任何可执行路径配置。"
        return 0
    fi

    local script_path
    local error_found=0

    # 检查每个路径
    for script_path in $crontab_entries; do
        if [[ ! -f "$script_path" ]]; then
            echo "警告: 文件 '$script_path' 不存在。"
            continue
        fi

	# 检查文件权限
	local perm=$(stat -c "%A" "$script_path")
	local owner_writable=${perm:2:1}  # 获取属主写权限位
	local group_writable=${perm:5:1}  # 获取属组写权限位
	local others_writable=${perm:8:1}  # 获取其他用户写权限位
	
	if [[ "$group_writable" = "w" || "$others_writable" = "w" ]]; then
	    echo "检测失败: '$script_path' 低权限用户可写。"
	    error_found=1
	fi

    done

    if [ "$error_found" -eq 0 ]; then
        echo "检查成功:所有脚本均配置正确，只有属主可写。"
        return 0
    else
        return 1
    fi
}

# 调用函数并处理返回值
if check_crontab_scripts; then
    exit 0
else
    exit 1
fi


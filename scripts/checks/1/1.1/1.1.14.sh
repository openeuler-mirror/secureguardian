#!/bin/bash

# 定义期望的权限设置
declare -A expected_permissions=(
    ["/etc/passwd"]="644"
    ["/etc/group"]="644"
    ["/etc/shadow"]="000"
    ["/etc/gshadow"]="000"
    ["/etc/passwd-"]="644"
    ["/etc/shadow-"]="000"
    ["/etc/group-"]="644"
    ["/etc/gshadow-"]="000"
    ["/etc/ssh/sshd_config"]="600"
    # 添加更多文件和期望的权限
)

# 通过参数传入的例外列表
exceptions=("$@")

# 检测关键文件和目录的权限是否最小化
check_min_permissions() {
    local issue_found=0

    for path in "${!expected_permissions[@]}"; do
        # 如果文件或目录在例外列表中，跳过检查
        if [[ " ${exceptions[*]} " =~ " ${path} " ]]; then
            echo "Skipping exception: $path"
            continue
        fi

        # 检查文件或目录是否存在
        if [ ! -e "$path" ]; then
            echo "Warning: $path does not exist."
            continue
        fi

        # 获取文件的实际权限并格式化为三位数
        actual_perm=$(stat -c "%a" "$path" | awk '{printf "%03d", $0}')

        # 对比实际权限和期望权限
        if [ "$actual_perm" != "${expected_permissions[$path]}" ]; then
            echo "Permission issue: $path (Expected: ${expected_permissions[$path]}, Actual: $actual_perm)"
            issue_found=1
        fi
    done

    if [ $issue_found -eq 1 ]; then
        echo "至少一个指定文件或目录未设置正确权限。"
        return 1
    else
        echo "所有检测的文件和目录权限设置正确。"
        return 0
    fi
}

# 执行权限检查并捕获返回值
check_min_permissions
result=$?

# 根据返回值决定输出
if [ $result -eq 0 ]; then
    #echo "检测通过。"
    exit 0
else
    #echo "检测不通过。"
    exit 1
fi


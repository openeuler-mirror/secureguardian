#!/bin/bash

# 检查Warning Banners是否包含合理的信息和权限设置
check_warning_banners() {
    local files=("/etc/motd" "/etc/issue" "/etc/issue.net")
    local issues=0

    for file in "${files[@]}"; do

        # 检查文件权限
        if [[ $(stat -c "%a" "$file" 2>/dev/null) != "644" ]]; then
            echo "错误：$file 的权限不是644。"
            issues=$((issues+1))
        fi

        # 检查文件所有权是否为root
        if [[ $(stat -c "%U" "$file" 2>/dev/null) != "root" ]]; then
            echo "错误：$file 的所有权不是root。"
            issues=$((issues+1))
        fi

        # 检查文件内容是否可能包含敏感信息
        if grep -qi -E "(Ubuntu|CentOS|Debian|kernel|server|Kylin|openEuler)" "$file"; then
            echo "错误：$file 包含可能的敏感信息。"
            issues=$((issues+1))
        fi
    done

    # 根据发现的问题数量返回状态
    if [ "$issues" -ne 0 ]; then
        return 1  # 存在问题
    else
        echo "检查成功:所有检查的文件均符合要求。"
        return 0  # 检查通过
    fi
}

# 调用检查函数并处理返回值
if check_warning_banners; then
    exit 0  # 检查通过，脚本成功退出
else
    echo "检查失败:存在配置不符合要求，请检查。"
    exit 1  # 检查未通过
fi


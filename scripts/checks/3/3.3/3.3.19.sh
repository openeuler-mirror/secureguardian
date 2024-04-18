#!/bin/bash

# 功能: 检查系统中是否预设置了 known_hosts 文件
# 用法: 3.3.19.sh [-e <exceptions>]

usage() {
    echo "Usage: $0 [-e <exceptions>]"
    echo "  -e, --exceptions   Comma-separated list of directories to exclude from the check"
    echo "  -h, --help         Display this help message"
}

# 解析命令行参数
EXCEPTIONS=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--exceptions) EXCEPTIONS="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# 将逗号分隔的例外转换为find命令的排除参数
EXCLUDES=""
if [[ -n "$EXCEPTIONS" ]]; then
    IFS=',' read -r -a dirs <<< "$EXCEPTIONS"
    for dir in "${dirs[@]}"; do
        # Ensure proper handling of directory names with spaces
        EXCLUDES+=" ! -path \"$dir*/*\" ! -path \"$dir*\""
    done
fi

# 定义检查函数
check_known_hosts() {
    local found_files=0

    # 使用find命令查找所有用户主目录中的known_hosts文件，排除例外
    local files=$(eval "find /home/ /root/ -type f -name known_hosts $EXCLUDES 2>/dev/null")

    if [[ -n "$files" ]]; then
        echo "检测到预设置的 known_hosts 文件:"
        echo "$files"
        found_files=1
    else
        echo "检测成功:未检测到预设置的 known_hosts 文件。"
    fi

    return $found_files
}

# 调用检查函数并处理结果
if check_known_hosts; then
    exit 0  # 未找到文件，检查通过
else
    echo "检测失败: 系统中预设置了 known_hosts 文件。"
    exit 1  # 找到文件，检查未通过
fi


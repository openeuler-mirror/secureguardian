#!/bin/bash

# 默认区域
default_zone="public"

# 函数：显示使用说明
show_usage() {
    echo "用法：$0 [-z <expected_zone>]"
    echo "默认情况下，检查区域是否设置为 'public'。"
    echo "示例：$0 -z public           # 检查默认区域是否为public"
    echo "      $0 -z internal        # 检查默认区域是否为internal"
}

# 函数：检查默认区域
check_default_zone() {
    local expected_zone=$1
    local actual_zone=$(firewall-cmd --get-default-zone)
    
    if [[ "$actual_zone" == "$expected_zone" ]]; then
        echo "检测成功: 默认区域配置正确，当前区域为：$actual_zone。"
        return 0
    else
        echo "检测失败: 当前默认区域为 $actual_zone, 但预期为 $expected_zone。"
        return 1
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -z|--zone)
            default_zone="$2"
            shift; shift
            ;;
        /?|--help)
            show_usage
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# 执行检查
check_default_zone "$default_zone"
exit $?

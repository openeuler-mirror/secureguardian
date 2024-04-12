#!/bin/bash

# 函数：检查历史命令记录数量设置
check_hist_size() {
    # 默认历史命令记录数量
    local default_hist_size=100
    # 初始化变量
    local hist_size_target
    local hist_size_actual
    local issues=0

    # 获取参数
    while getopts "s:" opt; do
        case ${opt} in
            s)
                hist_size_target=${OPTARG}
                ;;
            \?)
                echo "Usage: cmd [-s desired_hist_size]"
                return 1
                ;;
        esac
    done

    # 如果用户没有指定-s参数，则使用默认的历史命令记录数量
    local hist_size=${hist_size_target:-$default_hist_size}

    # 从环境变量获取HISTSIZE的当前值
    hist_size_actual=$(echo $HISTSIZE)

    # 检查HISTSIZE的当前值是否设置且在指定范围内
    if [[ -z "$hist_size_actual" || "$hist_size_actual" -lt 1 || "$hist_size_actual" -gt "$hist_size" ]]; then
        echo "环境变量 HISTSIZE 设置不符合要求（当前值：$hist_size_actual，期望值：1-$hist_size）。"
        issues=1
    fi

    if [ "$issues" -eq 0 ]; then
        echo "检查成功:历史命令记录数量设置符合要求。"
        return 0
    else
        echo "检查失败:存在配置不符合要求，请检查。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_hist_size "$@"; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过
fi


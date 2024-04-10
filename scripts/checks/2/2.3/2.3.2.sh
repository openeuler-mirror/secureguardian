#!/bin/bash

# 函数：检查会话超时时间设置
check_session_timeout() {
    local expected_timeout="$1"  # 期望的超时时间，通过参数传入
    local profile_file="/etc/profile"

    # 检查/etc/profile中TMOUT设置的正则表达式
    local regex="^export\s+TMOUT="

    # 如果提供了具体的超时时间，则加入具体值到正则表达式中
    if [[ -n "$expected_timeout" ]]; then
        regex+="\s*$expected_timeout"
    fi

    # 根据提供的情况进行检查
    if grep -Eq "$regex" "$profile_file"; then
        if [[ -n "$expected_timeout" ]]; then
            echo "检测通过：会话超时时间已正确设置为 $expected_timeout 秒。"
        else
            echo "检测通过：会话超时时间已在 $profile_file 中设置。"
        fi
        return 0
    else
        if [[ -n "$expected_timeout" ]]; then
            echo "检测失败：会话超时时间未设置为 $expected_timeout 秒。"
        else
            echo "检测失败：会话超时时间未在 $profile_file 中设置。"
        fi
        return 1
    fi
}

# 主函数
main() {
    # 默认为空，即不检查具体值
    local timeout_value=""

    # 通过命令行参数获取期望的超时时间，如果提供了
    while getopts ":t:" opt; do
        case ${opt} in
            t ) timeout_value="$OPTARG" ;;
            \? ) echo "用法: $0 [-t 超时时间（秒）]"; exit 1 ;;
        esac
    done

    # 调用函数检查会话超时时间设置
    check_session_timeout "$timeout_value"
    local result=$?

    exit $result
}

# 脚本执行入口
main "$@"


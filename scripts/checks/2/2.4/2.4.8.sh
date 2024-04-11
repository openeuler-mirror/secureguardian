#!/bin/bash

# 定义检查ALWAYS_SET_PATH配置的函数
check_always_set_path() {
    local login_defs="/etc/login.defs"
    local expected_setting="ALWAYS_SET_PATH yes"

    if [ ! -f "$login_defs" ]; then
        echo "检测失败: $login_defs 文件不存在。"
        return 1
    fi

    # 检查ALWAYS_SET_PATH设置是否存在并设置为yes
    # 忽略行首的空白字符和注释
    if grep -Eqs "^\s*ALWAYS_SET_PATH\s+yes\b" "$login_defs"; then
        echo "检测成功: $login_defs 中正确配置了 ALWAYS_SET_PATH。"
        return 0
    else
        echo "检测失败: $login_defs 中未正确配置 ALWAYS_SET_PATH。"
        return 1
    fi
}

# 解析参数
while getopts ":?" opt; do
    case ${opt} in
        \? | h )
            echo "用法: $0 [/?]"
            echo "/? 显示这个帮助信息。"
            exit 0
            ;;
        * )
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# 调用检查函数并退出脚本
check_always_set_path
exit $?


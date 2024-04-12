#!/bin/bash

# 显示帮助信息
show_usage() {
    echo "用法: $0 /? [-h] [-c <配置文件路径>]"
    echo "  /? 或 -h              显示帮助信息"
    echo "  -c <路径>, --config=<路径>  指定AIDE配置文件的路径，默认为/etc/aide.conf"
}

# 解析命令行参数
parse_args() {
    for arg in "$@"
    do
        case $arg in
            /?|-h)
                show_usage
                exit 0
                ;;
            -c|--config=*)
                config_path="${arg#*=}"
                shift # 移除当前参数
                ;;
            *)
                # 不识别的选项
                echo "未知选项: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 默认配置文件路径
config_path="/etc/aide.conf"

# 检查AIDE安装状态
check_aide_installed() {
    if ! command -v aide &>/dev/null; then
        echo "检测失败: AIDE软件未安装"
        return 1
    fi
    return 0
}

# 检查AIDE配置文件
check_aide_config() {
    if [ ! -f "$config_path" ]; then
        echo "检测失败: AIDE配置文件不存在于指定路径: $config_path"
        return 1
    fi

    if ! grep -q 'NORMAL' "$config_path"; then
        echo "检测失败: AIDE配置文件中未配置监控目录"
        return 1
    fi

    return 0
}

# 检查AIDE基准数据库
check_aide_database() {
    if [ ! -f "/var/lib/aide/aide.db.gz" ]; then
        echo "检测失败: AIDE基准数据库不存在"
        return 1
    fi
    return 0
}

# 主逻辑
main() {
    # 解析命令行参数
    parse_args "$@"

    # 依次调用检查函数
    if check_aide_installed && check_aide_config && check_aide_database; then
        echo "检查成功: AIDE入侵检测功能启用且配置正确"
        exit 0
    else
        exit 1
    fi
}

main "$@"


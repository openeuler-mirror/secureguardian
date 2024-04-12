#!/bin/bash

# 检查haveged服务状态的函数
check_haveged_status() {
    # 检查haveged服务是否处于活动状态
    local status=$(systemctl is-active haveged)
    if [ "$status" == "active" ]; then
        echo "检测成功: haveged服务正在运行。"
        return 0
    else
        echo "检测失败: haveged服务未启动或处于非活动状态。"
        return 1
    fi
}

# 主逻辑
main() {
     
    # 调用检查haveged状态的函数
    if check_haveged_status; then
        exit 0  # 检查成功，服务正在运行
    else
        exit 1  # 检查未通过，服务未启动或非活动状态
    fi
}

main "$@"


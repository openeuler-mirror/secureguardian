#!/bin/bash

# 定义检查标签为unconfined_service_t的进程的函数
check_unconfined_service_t_processes() {
    # 使用ps和grep命令检查是否存在标签为unconfined_service_t的进程
    if ps -eZ | grep -q 'unconfined_service_t'; then
        echo "检测失败: 系统中存在标签为unconfined_service_t的进程。"
        # 打印具体的进程信息以便进一步分析
        ps -eZ | grep 'unconfined_service_t'
        return 1
    else
        echo "检测成功: 系统中没有标签为unconfined_service_t的进程。"
        return 0
    fi
}

# 调用检查函数
check_unconfined_service_t_processes
exit $?


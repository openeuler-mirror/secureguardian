#!/bin/bash

# 检查是否安装了CUPS软件
check_cups_installed() {
    if rpm -qa | grep -q "cups"; then
        echo "CUPS打印服务软件已安装。"
        return 1
    else
        echo "CUPS打印服务软件未安装，符合规范要求。"
        return 0
    fi
}

# 执行检查
check_cups_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


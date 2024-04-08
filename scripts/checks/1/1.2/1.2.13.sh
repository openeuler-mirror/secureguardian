#!/bin/bash

# 检查是否安装了ypbind软件
check_ypbind_installed() {
    if rpm -qa | grep -q "ypbind"; then
        echo "NIS客户端软件ypbind已安装。"
        return 1
    else
        echo "NIS客户端软件ypbind未安装，符合规范要求。"
        return 0
    fi
}

# 执行检查
check_ypbind_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


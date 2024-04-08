#!/bin/bash

# 检查是否安装了ypserv软件
check_ypserv_installed() {
    if rpm -qa | grep -q "ypserv"; then
        echo "NIS服务端软件ypserv已安装。"
        return 1
    else
        echo "NIS服务端软件ypserv未安装，符合规范要求。"
        return 0
    fi
}

# 执行检查
check_ypserv_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval


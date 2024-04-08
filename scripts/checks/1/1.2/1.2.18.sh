#!/bin/bash

#!/bin/bash

# 检测X Window系统的组件是否已安装
check_x_window_installed() {
    # 使用rpm命令查找所有与X Window系统相关的包，但不直接输出结果
    if rpm -qa | grep -E "xorg-x11" &>/dev/null; then
        echo "检测不通过。已安装X Window系统的组件。"
        return 1
    else
        echo "检测通过。X Window系统的组件未安装。"
        return 0
    fi
}

# 执行检查
check_x_window_installed

# 捕获函数返回值
retval=$?

# 以此值退出脚本
exit $retval

#!/bin/bash

# 检查是否安装了avahi软件
check_avahi_installed() {
    installed=$(rpm -qa | grep -q "avahi" && echo "yes" || echo "no")
    if [ "$installed" == "yes" ]; then
        echo "avahi软件已安装。"
        return 0
    else
        echo "avahi软件未安装，符合规范要求。"
        return 1
    fi
}

# 检查avahi服务是否启用
check_avahi_service() {
    if systemctl list-unit-files | grep -qw "avahi-daemon.service"; then
        status=$(systemctl is-enabled avahi-daemon 2>/dev/null)
        if [ "$status" == "disabled" ] || [ "$status" == "masked" ]; then
            echo "avahi服务已禁用或被屏蔽，符合规范要求。"
            return 0
        else
            echo "avahi服务已启用，不符合规范要求。"
            return 1
        fi
    else
        echo "avahi服务未安装或不存在。"
        return 1
    fi
}

# 执行检查
if check_avahi_installed; then
    check_avahi_service
    exit $?
else
    echo "未安装avahi软件，无需进一步操作。"
    exit 0
fi


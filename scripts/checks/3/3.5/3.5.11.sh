#!/bin/bash

# 功能说明：
# 此脚本用于检查系统是否已启用反向地址过滤（rp_filter），
# 这有助于防止IP地址欺骗和非法数据包入侵。

check_rp_filter() {
    # 检查所有接口和默认接口的反向地址过滤设置
    local all_rp_filter=$(sysctl -n net.ipv4.conf.all.rp_filter)
    local default_rp_filter=$(sysctl -n net.ipv4.conf.default.rp_filter)

    # 判断参数是否为1，即是否启用了反向地址过滤
    if [[ "$all_rp_filter" -eq 1 && "$default_rp_filter" -eq 1 ]]; then
        echo "检测成功: 所有接口和默认接口的反向地址过滤已启用。"
        return 0
    else
        echo "检测失败: 反向地址过滤未在所有接口或默认接口启用。当前设置为 all_rp_filter=$all_rp_filter, default_rp_filter=$default_rp_filter。建议修改配置。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_rp_filter; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


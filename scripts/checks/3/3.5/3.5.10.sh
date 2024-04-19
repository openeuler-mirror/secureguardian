#!/bin/bash

# 功能说明：
# 此脚本用于检查系统是否设置了 icmp_ignore_bogus_error_responses 参数为 1，
# 从而避免记录无效的ICMP错误响应，保护系统免受无用日志信息的影响。

check_icmp_ignore_setting() {
    # 获取当前系统参数设置
    local ignore_bogus=$(sysctl -n net.ipv4.icmp_ignore_bogus_error_responses)

    # 判断参数是否为1，即是否忽略伪造的ICMP错误响应
    if [ "$ignore_bogus" -eq 1 ]; then
        echo "检测成功: 系统已设置为忽略伪造的ICMP错误响应。"
        return 0
    else
        echo "检测失败: 系统未设置为忽略ICMP错误响应。建议修改系统配置。"
        return 1
    fi
}

# 调用函数并处理返回值
if check_icmp_ignore_setting; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


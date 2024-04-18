#!/bin/bash

# 功能说明：
# 该脚本用于检查cron和at的配置文件和相关目录的权限，确保它们的安全配置。
# 脚本会确保相关文件和目录的group和other用户没有任何访问权限（读、写、执行），
# 确保所有配置文件和目录的属主和属组均为root，并检查cron服务是否启用以及不应存在的黑名单文件。

check_cron_and_at_configs() {
    local failure=0
    local items=(
        "/etc/crontab"
        "/etc/cron.allow"
        "/etc/at.allow"
        "/etc/cron.hourly"
        "/etc/cron.daily"
        "/etc/cron.weekly"
        "/etc/cron.monthly"
        "/etc/cron.d"
    )

    # 检查cron服务是否启用
    local cron_status=$(systemctl is-enabled crond)
    if [ "$cron_status" != "enabled" ]; then
        echo "检测失败: cron服务未启用。"
        failure=1
    fi

    # 检查文件和目录的权限和所有权
    for item in "${items[@]}"; do
        if [ -e "$item" ]; then
            local perm_info=$(stat -c "%a %U %G" "$item")
            local actual_perm=$(echo "$perm_info" | awk '{print $1}')
            local owner=$(echo "$perm_info" | awk '{print $2}')
            local group=$(echo "$perm_info" | awk '{print $3}')

            # 检查group和other用户的权限（应没有任何权限）
            local perm_o=${actual_perm:2:1}
            local perm_g=${actual_perm:1:1}
            if [[ "$perm_g" != "0" || "$perm_o" != "0" || "$owner" != "root" || "$group" != "root" ]]; then
                echo "检测失败: '$item' 权限或所有权不正确。期望权限：700或更严格，所有者：root，组：root。实际权限：$actual_perm，所有者：$owner，组：$group。"
                failure=1
            fi
        else
            echo "警告: '$item' 文件或目录不存在。"
            failure=1
        fi
    done

    # 确保黑名单文件不存在
    for deny_file in /etc/cron.deny /etc/at.deny; do
        if [ -e "$deny_file" ]; then
            echo "检测失败: 黑名单文件 '$deny_file' 不应存在。"
            failure=1
        fi
    done

    return $failure
}

# 调用函数并处理返回值
if check_cron_and_at_configs; then
    echo "检查成功:所有检查通过。"
    exit 0
else
    echo "检查未通过。"
    exit 1
fi


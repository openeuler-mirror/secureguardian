#!/bin/bash
# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Check Script for 1.1.15
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于检测并修复用户可打开文件数量的配置，确保其符合合理的软限制和硬限制值，以防止系统资源耗尽或用户无法打开必要文件。

# 接受命令行参数或使用默认值
expected_soft_limit=${1:-2000}
expected_hard_limit=${2:-524288}

limits_conf_file="/etc/security/limits.conf"
backup_limits_conf_file="/etc/security/limits.conf.bak"

# 公共检查逻辑
check_limits_common() {
    local current_soft_limit=$(ulimit -Sn)
    local current_hard_limit=$(ulimit -Hn)
    local soft_limit_status=0
    local hard_limit_status=0

    if [ "$current_soft_limit" -gt "$expected_soft_limit" ]; then
        echo "警告: 当前软限制值 $current_soft_limit 高于限值 $expected_soft_limit。"
        soft_limit_status=1
    else
        echo "软限制值 $current_soft_limit 符合或低于限值。"
    fi

    if [ "$current_hard_limit" -gt "$expected_hard_limit" ]; then
        echo "警告: 当前硬限制值 $current_hard_limit 高于限值 $expected_hard_limit。"
        hard_limit_status=1
    else
        echo "硬限制值 $current_hard_limit 符合或低于限值。"
    fi

    if [[ $soft_limit_status -eq 1 || $hard_limit_status -eq 1 ]]; then
        return 1
    else
        return 0
    fi
}

# 检查函数
check_limits() {
    check_limits_common
    return $?
}

# 修复函数
fix_limits() {
    if ! check_limits_common; then
        local current_soft_limit=$(ulimit -Sn)
        local current_hard_limit=$(ulimit -Hn)

        if [ "$current_soft_limit" -gt "$expected_soft_limit" ]; then
            ulimit -Sn "$expected_soft_limit"
            if [[ $? -ne 0 ]]; then
                echo "修复失败: 无法将软限制值修改为 $expected_soft_limit"
                return 1
            else
                echo "修复成功: 软限制值已修改为 $expected_soft_limit"
            fi
        fi

        if [ "$current_hard_limit" -gt "$expected_hard_limit" ]; then
            ulimit -Hn "$expected_hard_limit"
            if [[ $? -ne 0 ]]; then
                echo "修复失败: 无法将硬限制值修改为 $expected_hard_limit"
                return 1
            else
                echo "修复成功: 硬限制值已修改为 $expected_hard_limit"
            fi
        fi

        # 更新/etc/security/limits.conf文件
        if [ ! -f "$backup_limits_conf_file" ]; then
            cp "$limits_conf_file" "$backup_limits_conf_file"
            echo "备份 $limits_conf_file 为 $backup_limits_conf_file"
        fi

        # 添加或更新配置
        grep -q "^\*\s\+soft\s\+nofile\s\+" "$limits_conf_file" && sed -i "s/^\*\s\+soft\s\+nofile\s\+.*/\* soft nofile $expected_soft_limit/" "$limits_conf_file" || echo "* soft nofile $expected_soft_limit" >> "$limits_conf_file"
        grep -q "^\*\s\+hard\s\+nofile\s\+" "$limits_conf_file" && sed -i "s/^\*\s\+hard\s\+nofile\s\+.*/\* hard nofile $expected_hard_limit/" "$limits_conf_file" || echo "* hard nofile $expected_hard_limit" >> "$limits_conf_file"

        echo "更新 $limits_conf_file 以确保全系统范围内的限制值生效。"

        # 再次检查修复结果
        check_limits_common
        if [ $? -eq 0 ]; then
            echo "修复完成，所有打开文件数量限制的配置均符合或低于限值。"
            return 0
        else
            echo "修复失败，仍存在配置不合理的项目。"
            return 1
        fi
    else
        echo "所有打开文件数量限制的配置均符合或低于限值。"
        return 0
    fi
}

# 自测部分
self_test() {
    echo "自测: 修改当前会话的软限制和硬限制值"

    # 设置初始测试限制值
    ulimit -Sn 3000
    ulimit -Hn 6000

    echo "初始软限制值: $(ulimit -Sn)"
    echo "初始硬限制值: $(ulimit -Hn)"

    # 运行修复函数
    expected_soft_limit=2000
    expected_hard_limit=5000
    fix_limits

    # 检查自测结果
    current_soft_limit=$(ulimit -Sn)
    current_hard_limit=$(ulimit -Hn)

    if [[ "$current_soft_limit" -le "$expected_soft_limit" && "$current_hard_limit" -le "$expected_hard_limit" ]]; then
        echo "自测成功: 当前会话的软限制和硬限制值已正确修复"
        return 0
    else
        echo "自测失败: 当前会话的软限制或硬限制值未正确修复"
        return 1
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [软限制] [硬限制]"
    echo "选项:"
    echo "  /?                          显示此帮助信息"
}

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
elif [[ "$1" == "/?" ]]; then
    show_usage
    exit 0
else
    # 执行检测和修复
    if check_limits; then
        echo "修复成功:所有打开文件数量限制的配置均符合或低于限值。"
        exit 0
    else
        echo "修复失败:存在配置不合理的项目，尝试进行修复。"
        fix_limits
        exit $?
    fi
fi


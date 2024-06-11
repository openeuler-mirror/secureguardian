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
# Description: Security Baseline Check Script for 3.5.20
#
# #######################################################################################

# 功能说明：
# 检查系统的core dump配置是否正确。如果core dump已禁用，验证通过。如果启用，确保core dump文件的路径和权限正确配置。

# 使用帮助
usage() {
    echo "用法: $0"
    echo "该脚本不需要任何参数，自动检测core dump配置是否符合安全要求。"
    exit 1
}

# 定义检查核心转储配置的函数
check_core_dump_config() {
    local core_size=$(ulimit -c)

    if [[ "$core_size" -eq 0 ]]; then
        echo "核心转储已禁用，配置正确。"
        return 0
    else
        local core_path=$(sysctl kernel.core_pattern | awk -F"=" '{print $2}' | xargs)
        
        if [[ "${core_path}" =~ \| ]]; then
            echo "检测失败:核心转储由专门的处理程序管理: $core_path,需对日志输入的路径进行限制"
            return 1
        elif [[ "${core_path}" =~ ^/.+ ]]; then
            local core_dir=$(dirname "${core_path}")
            if [[ -d "${core_dir}" ]]; then
                local rights_digit=$(stat -c%a "${core_dir}")
                if [[ "${rights_digit}" =~ ^(700|1770|1777)$ ]]; then
                    echo "核心转储配置正确，路径：$core_dir，权限：$rights_digit"
                    return 0
                else
                    echo "检查失败:权限[${rights_digit}]的目录[${core_dir}]不安全，必须是700, 1770或1777"
                    return 1
                fi
            else
                echo "检查失败:核心转储路径[$core_dir]不存在"
                return 1
            fi
        else
            echo "检查失败:核心转储路径配置错误或未正确设置为绝对路径: $core_path"
            return 1
        fi
    fi
}

# 主脚本部分，调用检查函数
if check_core_dump_config; then
    exit 0
else
    exit 1
fi


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
# Description: Security Baseline Check Script for 3.5.1
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查Linux内核的地址空间布局随机化（ASLR）设置。
# ASLR有助于防止缓冲区溢出攻击通过使内存地址难以预测。
# 脚本检查ASLR的配置是否设置为最高级别（2），以确保最佳的安全防护。

check_aslr_setting() {
    local aslr_file="/proc/sys/kernel/randomize_va_space"
    local expected_value="2"
    local current_value

    if [ ! -f "$aslr_file" ]; then
        echo "检测失败: ASLR配置文件$aslr_file不存在。"
        return 1
    fi

    current_value=$(cat "$aslr_file")
    if [ "$current_value" != "$expected_value" ]; then
        echo "检测失败: ASLR设置不正确。期望值为$expected_value，当前值为$current_value。"
        return 1
    else
        echo "ASLR设置正确，当前值为$expected_value。"
    fi

    return 0
}

# 调用函数并处理返回值
if check_aslr_setting; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


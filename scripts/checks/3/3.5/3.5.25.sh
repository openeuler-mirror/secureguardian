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
# Description: Security Baseline Check Script for 3.5.25
#
# #######################################################################################

# 功能说明：
# 此脚本用于检查是否开启内核模块签名加固。
# 此脚本启动命令行中是否设置module.sig_enforce。

check_mod_sign() {
    if ! grep -q 'module.sig_enforce' /proc/cmdline; then
        echo "检测失败: 系统未启用内核模块签名"
        return 1
    else
        echo "检查成功: 系统已启用内核模块签名"
        return 0
    fi
}

# 调用函数并处理返回值
if check_mod_sign; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过，脚本以失败退出
fi


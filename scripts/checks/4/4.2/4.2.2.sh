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
# Description: Security Baseline Check Script for 4.2.2
#
# #######################################################################################

# 检测是否配置了系统认证相关日志
check_auth_logs() {
    # 搜索rsyslog配置中关于认证日志的配置
    local auth_log_config=$(grep auth /etc/rsyslog.conf | grep -v "^#")
    
    # 检测是否包含authpriv.*
    if echo "$auth_log_config" | grep -q "authpriv.*"; then
        echo "检查通过: 系统认证相关日志已配置。"
        return 0
    else
        echo "检测失败: 系统认证相关日志未配置。"
        return 1
    fi
}

# 调用检测函数并处理返回值
if check_auth_logs; then
    exit 0
else
    exit 1
fi


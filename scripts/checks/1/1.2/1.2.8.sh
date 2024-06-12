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
# Description: Security Baseline Check Script for 1.2.8
#
# #######################################################################################

# 检查是否安装了rsync软件
check_rsync_installed() {
    installed=$(rpm -qa | grep -q "rsync" && echo "yes" || echo "no")
    if [ "$installed" == "yes" ]; then
        echo "rsync软件已安装。"
        return 0
    else
        echo "rsync软件未安装，符合规范要求。"
        return 1
    fi
}

# 检查rsync服务是否开启
check_rsync_service() {
    if systemctl list-unit-files | grep -qw "rsyncd.service"; then
        status=$(systemctl is-enabled rsyncd 2>/dev/null)
        if [ "$status" == "disabled" ] || [ "$status" == "masked" ]; then
            echo "rsync服务已禁用或被屏蔽，符合规范要求。"
            return 0
        else
            echo "rsync服务已启用，不符合规范要求。"
            return 1
        fi
    else
        echo "rsync服务未安装或不存在。"
        return 1
    fi
}

# 执行检查
if check_rsync_installed; then
    check_rsync_service
else
    echo "未安装rsync软件，无需进一步操作，但建议检查是否需要移除rsync软件。"
    exit 0
fi


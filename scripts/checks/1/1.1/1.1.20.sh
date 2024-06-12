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
# Description: Security Baseline Check Script for 1.1.20
#
# #######################################################################################

# 检查系统级配置是否设置了PATH
check_system_path() {
    echo "检查系统级配置中PATH设置..."
    local issue_found=0
    local system_files=("/etc/profile" $(find /etc/profile.d/ -type f))

    for file in "${system_files[@]}"; do
        if [ -f "$file" ] && grep -q "export PATH=" "$file"; then
            if grep "export PATH=" "$file" | grep -q ":"; then
                echo "警告: $file 中的 PATH 设置可能包含除默认设置外的其他路径。"
                issue_found=1
            fi
        fi
    done

    return $issue_found
}

# 检查所有用户的.bashrc和.bash_profile是否包含不安全的PATH设置
check_users_path() {
    #echo "检查所有用户配置中PATH设置..."
    local issue_found=0

    while IFS=: read -r username _ _ _ _ homedir shell; do
        # 跳过nologin用户
        if [[ "$shell" == */nologin ]]; then
            continue
        fi

        # 忽略不存在的家目录
        if [ ! -d "$homedir" ]; then
            continue
        fi

        # 检查用户家目录下的配置文件
        for file in "$homedir/.bashrc" "$homedir/.bash_profile"; do
            if [ -f "$file" ] && grep -q "export PATH=" "$file"; then
                if grep "export PATH=" "$file" | grep -q ":"; then
                    echo "$file 中的 PATH 设置可能包含除默认设置外的其他路径。"
                    issue_found=1
                fi
            fi
        done
    done < /etc/passwd

    return $issue_found
}

# 执行检查
check_system_path
result_system=$?

check_users_path
result_users=$?

if [ $result_system -eq 0 ] && [ $result_users -eq 0 ]; then
    echo "PATH 环境变量设置检查通过，未在系统和用户配置中发现不当设置。"
    exit 0
else
    #echo "PATH 环境变量设置检查未通过，请根据以上提示进行必要的调整。"
    exit 1
fi


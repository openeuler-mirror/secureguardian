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
# Description: Security Baseline Check Script for 1.1.19
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于修复用户和系统配置文件中不正确设置的LD_LIBRARY_PATH变量。确保系统安全，防止动态库加载安全风险。
# 检查和修复用户的.bashrc和.bash_profile中设置的LD_LIBRARY_PATH
fix_users_ld_library_path() {
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

        # 修复用户家目录下的配置文件
        for file in "$homedir/.bashrc" "$homedir/.bash_profile"; do
            if [ -f "$file" ]; then
                if grep -q "^[^#]*LD_LIBRARY_PATH" "$file"; then
                    echo "在 $file 中发现未注释的 LD_LIBRARY_PATH 设置，注释掉。"
                    sed -i 's/^\([^#]*LD_LIBRARY_PATH.*\)$/# \1/' "$file"
                    issue_found=1
                elif grep -q "#.*LD_LIBRARY_PATH" "$file"; then
                    echo "在 $file 中发现注释掉的 LD_LIBRARY_PATH 设置，保留。"
                    issue_found=1
                fi
            fi
        done
    done < /etc/passwd

    return $issue_found
}

# 检查和修复系统级配置文件中设置的LD_LIBRARY_PATH
fix_system_ld_library_path() {
    local issue_found=0

    for file in "/etc/profile" "/etc/bashrc"; do
        if [ -f "$file" ]; then
            if grep -q "^[^#]*LD_LIBRARY_PATH" "$file"; then
                echo "在 $file 中发现未注释的 LD_LIBRARY_PATH 设置，注释掉。"
                sed -i 's/^\([^#]*LD_LIBRARY_PATH.*\)$/# \1/' "$file"
                issue_found=1
            elif grep -q "#.*LD_LIBRARY_PATH" "$file"; then
                echo "在 $file 中发现注释掉的 LD_LIBRARY_PATH 设置，保留。"
                issue_found=1
            fi
        fi
    done

    return $issue_found
}

# 自测部分
self_test() {
    local test_user="testuser"
    local test_homedir="/home/$test_user"
    local test_bashrc="$test_homedir/.bashrc"
    local test_bash_profile="$test_homedir/.bash_profile"

    echo "自测: 创建测试用户和配置文件"

    # 创建测试用户和家目录
    useradd -m "$test_user"
    if [ $? -ne 0 ]; then
        echo "自测失败: 无法创建测试用户。"
        return 1
    fi
    echo "export LD_LIBRARY_PATH=/home/testlib" > "$test_bashrc"
    echo "export LD_LIBRARY_PATH=/home/testlib" > "$test_bash_profile"

    # 检查修复前的设置
    if grep -q "LD_LIBRARY_PATH" "$test_bashrc" || grep -q "LD_LIBRARY_PATH" "$test_bash_profile"; then
        echo "自测前: 检测到测试用户配置文件中的LD_LIBRARY_PATH设置。"
    else
        echo "自测失败: 未检测到测试用户配置文件中的LD_LIBRARY_PATH设置。"
        userdel -r "$test_user"
        return 1
    fi

    # 修复配置
    fix_users_ld_library_path

    # 检查修复后的设置
    if grep -q "^[^#]*LD_LIBRARY_PATH" "$test_bashrc" || grep -q "^[^#]*LD_LIBRARY_PATH" "$test_bash_profile"; then
        echo "自测失败: 测试用户配置文件中的LD_LIBRARY_PATH设置未修复。"
        userdel -r "$test_user"
        return 1
    else
        echo "自测成功: 测试用户配置文件中的LD_LIBRARY_PATH设置已修复。"
        userdel -r "$test_user"
        return 0
    fi
}

# 使用说明
show_usage() {
    echo "用法: $0 [--self-test]"
    echo "选项:"
    echo "  --self-test                进行自测"
    echo "  /?                         显示此帮助信息"
}

# 检查命令行参数
if [[ "$1" == "--self-test" ]]; then
    self_test
    exit $?
elif [[ "$1" == "/?" ]]; then
    show_usage
    exit 0
else
    # 执行修复
    fix_users_ld_library_path
    fix_system_ld_library_path
    echo "LD_LIBRARY_PATH设置已修复。"
    exit 0
fi


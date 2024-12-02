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
# Description: Security Baseline Fix Script for 2.4.8
#
# #######################################################################################
#
# 确保 su 命令继承用户环境变量时不会引入提权
# 修复逻辑：
# 1. 修改 /etc/login.defs 文件中的 ALWAYS_SET_PATH 配置为 "yes"；
# 2. 如果配置不存在，则添加该配置；
# 3. 自测功能：构造错误配置，验证修复功能覆盖率；
#
# #######################################################################################

# 使用说明
usage() {
    echo "用法: $0 [--self-test]"
    echo "示例: $0 --self-test"
    echo "默认修复 /etc/login.defs 中的 ALWAYS_SET_PATH 配置，确保其为 yes。"
}

# 初始化参数
SELF_TEST=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            SELF_TEST=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 文件路径
LOGIN_DEFS="/etc/login.defs"

# 修复 ALWAYS_SET_PATH 配置
fix_always_set_path() {
    # 如果文件不存在，则创建文件
    if [ ! -f "$LOGIN_DEFS" ]; then
        echo "文件不存在，创建 $LOGIN_DEFS ..."
        touch "$LOGIN_DEFS"
    fi

    # 如果配置为 no 或缺失，则修复为 yes
    if grep -Eq "^\s*ALWAYS_SET_PATH\s+" "$LOGIN_DEFS"; then
        # 修改配置为 yes
        sed -i 's/^\s*ALWAYS_SET_PATH\s\+no\b/ALWAYS_SET_PATH yes/' "$LOGIN_DEFS"
        sed -i 's/^\s*ALWAYS_SET_PATH\s\+.*$/ALWAYS_SET_PATH yes/' "$LOGIN_DEFS"
        echo "修复完成: 修改 ALWAYS_SET_PATH 为 yes"
    else
        # 配置缺失，添加新配置
        echo "ALWAYS_SET_PATH yes" >> "$LOGIN_DEFS"
        echo "修复完成: 添加 ALWAYS_SET_PATH 配置为 yes"
    fi
}

# 自测功能
self_test() {
    echo "自测: 模拟问题场景。"

    # 创建测试文件
    local test_file="/tmp/login.defs.test"
    echo "模拟创建测试文件: $test_file"
    echo "ALWAYS_SET_PATH no" > "$test_file"

    # 执行修复
    LOGIN_DEFS="$test_file"  # 替换为测试文件
    fix_always_set_path

    # 检查修复结果
    if grep -Eq "^\s*ALWAYS_SET_PATH\s+yes\b" "$test_file"; then
        echo "自测成功: ALWAYS_SET_PATH 已正确修复为 yes。"
        rm -f "$test_file"  # 清理测试文件
        return 0
    else
        echo "自测失败: 修复未成功。"
        rm -f "$test_file"  # 清理测试文件
        return 1
    fi
}

# 主函数
main() {
    if [[ "$SELF_TEST" == true ]]; then
        self_test
        exit $?
    fi

    echo "开始修复 /etc/login.defs 文件..."
    fix_always_set_path
    exit 0
}

# 执行主函数
main "$@"


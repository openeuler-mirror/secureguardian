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
# Description: Security Baseline Fix Script for 2.4.10
#
# #######################################################################################

# 确保 SELinux 服务已启用
ensure_selinux_enabled() {
    local status
    status=$(getenforce)

    if [[ "$status" == "Disabled" ]]; then
        echo "错误: SELinux 未启用。请启用 SELinux 后再运行此脚本。"
        exit 1
    fi
}

# 检查 semanage 是否已安装
ensure_semanage_installed() {
    if ! command -v semanage &>/dev/null; then
        echo "错误: semanage 工具未安装。请安装 policycoreutils-python-utils 包。"
        exit 1
    fi
}

# 配置 SELinux 策略，确保更改永久生效
configure_selinux_policy() {
    local process_path="$1"
    local target_label="$2"

    echo "正在为进程路径 $process_path 配置SELinux策略，将标签设置为 $target_label"
    
    # 为路径设置合适的SELinux标签
    semanage fcontext -a -t "$target_label" "$process_path" 2>/dev/null || \
        semanage fcontext -m -t "$target_label" "$process_path"

    # 使用 restorecon 刷新 SELinux 上下文
    restorecon -R "$process_path"

    echo "SELinux策略已成功应用，路径 $process_path 的标签已更新为 $target_label"
}

# 处理传入的参数
process_args() {
    local process_path
    local target_label

    # 解析参数
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -p|--process-path)
                process_path="$2"
                shift 2
                ;;
            -t|--target-label)
                target_label="$2"
                shift 2
                ;;
            *)
                echo "无效选项: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$process_path" ] || [ -z "$target_label" ]; then
        echo "错误: 必须提供进程路径和目标标签。"
        exit 1
    fi

    # 确保 SELinux 启用并且 semanage 已安装
    ensure_selinux_enabled
    ensure_semanage_installed

    # 配置 SELinux 策略
    configure_selinux_policy "$process_path" "$target_label"
}

# 自测功能，用于模拟问题场景并验证修复逻辑
self_test() {
    local test_file="/tmp/unconfined_test.sh"
    local target_label="bin_t"
    
    # 确保 SELinux 启用并且 semanage 已安装
    ensure_selinux_enabled
    ensure_semanage_installed
    
    # 模拟创建文件，设置为 unconfined_service_t
    echo "模拟的测试脚本已创建，路径: $test_file"
    touch "$test_file"
    chcon -t unconfined_service_t "$test_file"

    echo "正在为进程路径 $test_file 配置SELinux策略，将标签设置为 $target_label"
    configure_selinux_policy "$test_file" "$target_label"

    # 验证标签是否正确修复
    current_label=$(ls -Z "$test_file" | awk '{print $1}')
    if [[ "$current_label" == "$target_label" ]]; then
        echo "自测成功: 测试脚本的标签已正确修复为 $current_label"
    else
        echo "自测失败: 测试脚本的标签未正确修复。当前标签: $current_label"
        exit 1
    fi
}

# 判断是否为自测模式
if [[ "$1" == "--self-test" ]]; then
    self_test
else
    process_args "$@"
fi


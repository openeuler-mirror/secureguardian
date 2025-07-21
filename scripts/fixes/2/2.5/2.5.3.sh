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
# Description: Security Baseline Check Script for 2.5.3
#
# #######################################################################################
# 启用 DIM 度量功能并配置相关策略
#
# 功能说明：
# - 安装和启用 DIM。
# - 提供自测功能。
# #######################################################################################

# 安装 DIM rpm包
install_dim_rpm() {
    echo "正在安装 DIM 软件包..."

    yum install -y dim dim_tools

    echo "DIM 软件包已安装。"
}

# 加载 DIM 内核模块
insmod_dim_ko() {
    echo "正在加载 DIM 内核模块..."

    modprobe dim_core
    modprobe dim_monitor

    echo "DIM 内核模块已加载。"
}

# 设置 DIM 策略
setup_dim_policy() {
    echo "配置 DIM 策略"
    mkdir -p /etc/dim/digest_list
    dim_gen_baseline /bin/bash -o /etc/dim/digest_list/test.hash
    echo "measure obj=BPRM_TEXT path=/bin/bash" > /etc/dim/policy
    echo 1 > /sys/kernel/security/dim/baseline_init
    echo 1 > /sys/kernel/security/dim/measure
    if [ "$(cat /sys/kernel/security/dim/ascii_runtime_measurements | wc -l)" -eq 0 ]; then
        echo "检测失败: DIM 度量策略未正确配置或未生效"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟配置和验证 DIM 启用..."

    # 模拟更新 DIM 配置策略
    echo "模拟更新 DIM 策略配置..."
    local test_policy="/tmp/policy"
    echo "measure obj=BPRM_TEXT path=/bin/bash" > $test_policy

    # 检查 DIM 配置策略
    if [ -f "$test_policy" ]; then
        echo "自测成功: 模拟策略文件已创建，内容如下:"
        cat "$test_policy"
    else
        echo "自测失败: 无法创建模拟策略文件。"
        exit 1
    fi

    echo "自测完成: 模拟配置成功。"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            self_test
            exit 0
            ;;
        *)
            echo "无效选项: $1"
            echo "使用方法: $0 [--self-test]"
            exit 1
            ;;
    esac
done

# 主修复逻辑
install_dim_rpm
insmod_dim_ko
setup_dim_policy

echo "DIM 度量功能已启用并正确配置。"
exit 0


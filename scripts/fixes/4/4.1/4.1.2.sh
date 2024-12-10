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
# Description: Security Baseline fix Script for 4.1.2
#
# #######################################################################################
# 确保审计日志已启用轮转
#
# 功能说明：
# - 确保 auditd 日志已配置 ROTATE 轮转机制
# - 修复必要的 ROTATE 配置
# - 提供自测功能，通过模拟场景验证修复逻辑

# 默认auditd配置文件路径
DEFAULT_CONFIG="/etc/audit/auditd.conf"
# 推荐的 ROTATE 配置
rec_num_logs="5"
rec_max_log_file_action="ROTATE"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [--self-test] [-?]"
    echo "选项:"
    echo "  -c, --config       指定auditd配置文件的路径，默认为/etc/audit/auditd.conf"
    echo "  --self-test        自测模式，模拟问题场景并验证修复逻辑"
    echo "  -?, --help         显示帮助信息"
    exit 0
}

# 修复 auditd 服务的 ROTATE 配置
fix_rotate_configuration() {
    local config_file=$1

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    # 确保 ROTATE 配置正确
    echo "正在修复 auditd 配置文件中的 ROTATE 设置..."
    if grep -qi "^num_logs" "$config_file"; then
        sed -i "s/^num_logs.*/num_logs = ${rec_num_logs}/i" "$config_file"
        echo "已更新配置文件中的 num_logs 设置为推荐值。"
    else
        echo "num_logs = ${rec_num_logs}" >> "$config_file"
        echo "已在配置文件末尾添加推荐的 num_logs 设置。"
    fi

    if grep -qi "^max_log_file_action" "$config_file"; then
	sed -i "s/^max_log_file_action.*/max_log_file_action = ${rec_max_log_file_action}/i" "$config_file"
	echo "已更新配置文件中的 max_log_file_action 设置为推荐值。"
    else
	echo "max_log_file_action = ${rec_max_log_file_action}" >> "$config_file"
	echo "已在配置文件末尾添加推荐的 max_log_file_action 设置。"
    fi

    # 重启 auditd 服务
    echo "正在重启 auditd 服务以应用配置更改..."
    systemctl restart auditd

    if [[ $? -eq 0 ]]; then
        echo "auditd 服务已成功重启，修复完成。"
    else
        echo "错误: auditd 服务重启失败，请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."

    local test_config="/tmp/auditd_config.test"
    cp "$DEFAULT_CONFIG" "$test_config"

    # 模拟错误配置
    echo "num_logs = 0" > "$test_config"
    echo "max_log_file_action = IGNORE" >> "$test_config"
    echo "已模拟错误配置文件: $test_config"

    # 调用修复函数
    fix_rotate_configuration "$test_config"

    # 验证修复结果
    local repaired_num_logs=$(grep -i "^num_logs" "$test_config" | awk '{print $3}')
    if [[ "$repaired_num_logs" == "$rec_num_logs" ]]; then
        echo "自测成功: 修复逻辑已正确设置 num_logs 。"
        rm -f "$test_config"
        return 0
    else
        echo "自测失败: 修复逻辑未正确设置 num_logs 。"
        rm -f "$test_config"
        return 1
    fi

    local repaired_max_log_file_action=$(grep -i "^max_log_file_action" "$test_config" | awk '{print $3}')
    if [[ "$repaired_max_log_file_action" == "$rec_max_log_file_action" ]]; then
	echo "自测成功: 修复逻辑已正确设置 max_log_file_action 。"
	rm -f "$test_config"
	return 0
    else
	echo "自测失败: 修复逻辑未正确设置 max_log_file_action 。"
	rm -f "$test_config"
	return 1
    fi
}

# 参数解析
config_file="$DEFAULT_CONFIG"
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
            shift 2 ;;
        --self-test)
            self_test
            exit $? ;;
        -\?|--help)
            usage ;;
        *)
            echo "无效选项: $1"
            usage ;;
    esac
done

# 执行修复逻辑
fix_rotate_configuration "$config_file"

echo "auditd 日志轮转配置已确保正确。"
exit 0



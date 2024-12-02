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
# Description: Security Baseline fix Script for 3.3.5
#
# #######################################################################################

#!/bin/bash
# #######################################################################################
#
# 确保 PAM 认证使能
#
# 功能说明：
# - 确保 SSH 配置文件中的 UsePAM 设置为 yes。
# - 修复必要的 UsePAM 配置。
# - 提供自测功能，通过模拟场景验证修复逻辑。
#
# #######################################################################################

# 默认SSH配置文件路径
DEFAULT_CONFIG="/etc/ssh/sshd_config"
config_file="$DEFAULT_CONFIG"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [--self-test] [-?]"
    echo "选项:"
    echo "  -c, --config    指定SSH配置文件的路径，默认为/etc/ssh/sshd_config"
    echo "  --self-test     自测模式，模拟问题场景并验证修复逻辑"
    echo "  -?, --help      显示帮助信息"
}

# 修复 PAM 认证配置
fix_pam_authentication() {
    local config_file=$1

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        echo "错误: 配置文件不存在: $config_file"
        exit 1
    fi

    # 确保 UsePAM 配置正确
    echo "正在修复 SSH 配置文件中的 UsePAM 设置..."
    if grep -qi "^UsePAM" "$config_file"; then
        sed -i "s/^UsePAM.*/UsePAM yes/i" "$config_file"
        echo "已更新配置文件中的 UsePAM 设置为 'yes'。"
    else
        echo "UsePAM yes" >> "$config_file"
        echo "已在配置文件末尾添加 UsePAM 设置为 'yes'。"
    fi

    # 重启 SSH 服务
    echo "正在重启 sshd 服务以应用配置更改..."
    systemctl restart sshd

    if [[ $? -eq 0 ]]; then
        echo "sshd 服务已成功重启，修复完成。"
    else
        echo "错误: sshd 服务重启失败，请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."

    local test_config="/tmp/sshd_config.test"
    cp "$config_file" "$test_config"

    # 模拟错误配置
    echo "UsePAM no" > "$test_config"
    echo "已模拟错误配置文件: $test_config"

    # 调用修复函数
    fix_pam_authentication "$test_config"

    # 验证修复结果
    local repaired_setting=$(grep -i "^UsePAM" "$test_config" | awk '{print $2}')

    if [[ "$repaired_setting" == "yes" ]]; then
        echo "自测成功: 修复逻辑已正确设置 UsePAM。"
        rm -f "$test_config"
        return 0
    else
        echo "自测失败: 修复逻辑未正确设置 UsePAM。"
        rm -f "$test_config"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            config_file="$2"
            shift 2 ;;
        --self-test)
            self_test
            exit $? ;;
        -\?|--help)
            usage
            exit 0 ;;
        *)
            echo "无效选项: $1"
            usage
            exit 1 ;;
    esac
done

# 执行修复逻辑
fix_pam_authentication "$config_file"

echo "PAM 认证配置已确保启用。"
exit 0


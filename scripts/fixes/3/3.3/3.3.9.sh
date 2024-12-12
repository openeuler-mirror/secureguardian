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
# Description: Security Baseline fix Script for 3.3.9
#
# #######################################################################################
#!/bin/bash
# #######################################################################################
#
# 禁用root用户通过SSH登录
#
# 功能说明：
# - 确保 SSH 配置文件中禁用 root 用户通过 SSH 登录。
# - 检查并修复 SSH 配置，确保 `PermitRootLogin` 设置为 `no`。
# - 提供自测功能，通过模拟场景验证修复逻辑。
#
# #######################################################################################

# 默认配置文件路径
SSHD_CONFIG="/etc/ssh/sshd_config"

# 显示使用帮助信息
usage() {
    echo "用法: $0 [-c config_path] [--self-test] [-?]"
    echo "选项:"
    echo "  -c, --config    指定SSH配置文件路径，默认为/etc/ssh/sshd_config"
    echo "  --self-test     自测模式，模拟问题场景并验证修复逻辑"
    echo "  -?, --help      显示帮助信息"
    exit 0
}

# 修复 PermitRootLogin 设置
fix_permit_root_login() {
    local sshd_config=$1

    # 检查配置文件是否存在
    if [[ ! -f "$sshd_config" ]]; then
        echo "错误: 配置文件不存在: $sshd_config"
        exit 1
    fi

    # 修复 PermitRootLogin 设置
    echo "正在修复 SSH 配置文件中的 PermitRootLogin 设置..."
    if grep -iq '^\s*PermitRootLogin\s*yes\b' "$sshd_config"; then
        # 将 PermitRootLogin 设置为 no
        sed -i 's/^\s*PermitRootLogin\s*yes/PermitRootLogin no/' "$sshd_config"
        echo "已修改配置文件中的 PermitRootLogin 为 no。"
    elif ! grep -q '^\s*PermitRootLogin' "$sshd_config"; then
        # 如果没有设置 PermitRootLogin，添加设置
        echo "PermitRootLogin no" >> "$sshd_config"
        echo "已在配置文件中添加 PermitRootLogin no 设置。"
    else
        echo "PermitRootLogin 已经设置为 no，无需修复。"
    fi

    # 重新加载 SSH 服务
    echo "正在重新加载 sshd 服务以应用配置更改..."
    systemctl restart sshd

    if [[ $? -eq 0 ]]; then
        echo "sshd 服务已成功重新加载，修复完成。"
    else
        echo "错误: sshd 服务重新加载失败，请手动检查配置。"
        exit 1
    fi
}

# 自测功能
self_test() {
    echo "开始自测: 模拟问题场景并验证修复逻辑..."

    local test_config="/tmp/sshd_config.test"
    cp "$SSHD_CONFIG" "$test_config"

    # 模拟错误配置
    echo "PermitRootLogin yes" > "$test_config"
    echo "已模拟错误配置文件: $test_config"

    # 调用修复函数
    fix_permit_root_login "$test_config"

    # 验证修复结果
    if grep -iq '^\s*PermitRootLogin\s+no\b' "$test_config"; then
        echo "自测成功: 修复逻辑已正确将 PermitRootLogin 设置为 no。"
        rm -f "$test_config"
        return 0
    else
        echo "自测失败: 修复逻辑未正确将 PermitRootLogin 设置为 no。"
        rm -f "$test_config"
        return 1
    fi
}

# 参数解析
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--config)
            SSHD_CONFIG="$2"
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
fix_permit_root_login "$SSHD_CONFIG"

echo "root 用户通过 SSH 登录已禁用。"
exit 0


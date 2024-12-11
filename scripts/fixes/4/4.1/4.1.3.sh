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
# Description: Security Baseline fix Script for 4.1.3
#
# #######################################################################################
# 确保 auditd 配置登录审计规则
#
# 功能说明:
# - 确保 auditd 已配置登录审计规则
# - 添加必要的登录审计规则
# - 提供自测功能, 通过模拟场景验证修复逻辑

# auditd 登录审计规则文件路径
DEFAULT_RULE="/etc/audit/rules.d/logins.rules"

# 显示使用帮助信息
usage() {
	echo "用法: $0 [-c rule_path] [--self-test] [-?]"
	echo "选项:"
	echo " -c, --config		指定auditd登录审计规则文件路径,默认为/etc/audit/rules.d/logins.rules"
	echo " --self-test		自测模式, 模拟问题场景并验证修复逻辑"
	echo " -?, --help		显示帮助信息"
	exit 0
}

# 检查登录审计规则是否已存在
check_audit_rule() {
	auditctl -l | grep -iE "lastlog" | grep -q "/var/log/lastlog"
}

# 主逻辑：检查并修复审计规则
ensure_audit_rule() {
	local rule_file=$1

	# 检查是否已经存在相应规则
	if check_audit_rule; then
		echo "登录审计规则 /var/log/lastlog 已经存在。"
	else
		echo "登录审计规则 /var/log/lastlog 缺失，正在添加。"
		if [[ ! -f "$rule_file" ]]; then
			echo "-w /var/log/lastlog -p wa -k logins" > $rule_file
			echo "已将审计规则添加到 $rule_file 文件中。"
		else
			echo "$rule_file 已存在, 请手动检查规则内容。"
			exit 1
		fi
		systemctl restart auditd
		echo "已重启 auditd 服务，新的规则已生效。"
	fi
}

# 自测功能
self_test() {
	echo "开始自测: 模拟问题场景并验证修复逻辑..."

	local test_rule="/tmp/logins.rules"

	# 调用修复函数
	ensure_audit_rule "$test_rule"
	echo "自测用临时规则文件 $test_rule"

	# 验证规则添加结果
	if check_audit_rule; then
		echo "登录审计规则 /var/log/lastlog 已经存在, 自测时无需添加"
	else
		grep -q "/var/log/lastlog" $test_rule
		if [[ $? -eq 0 ]]; then
			echo "登录审计规则自测添加成功"
			rm -f $test_rule
		else
			echo "登录审计规则自测添加失败"
			exit 1
		fi
	fi
}

# 参数解析
rule_file="$DEFAULT_RULE"
while [[ "$#" -gt 0 ]]; do
	case "$1" in
		-c | --config)
			rule_file="$2"
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

# 调用主逻辑函数
ensure_audit_rule "$rule_file"

# 完成
echo "已确保 auditd 配置登录审计规则。"
exit 0


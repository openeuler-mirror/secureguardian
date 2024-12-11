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
# Description: Security Baseline fix Script for 4.1.1
#
# #######################################################################################
# 确保 auditd 审计服务已启用、运行
#

# 检查 auditd 服务启用状态
check_enabled() {
	systemctl is-enabled auditd | grep -q "enabled"
}

# 启用 auditd 服务
enable_service() {
	echo "正在启用 auditd 服务..."
	systemctl enable auditd
}

# 检查 auditd 服务运行状态
check_active() {
	systemctl status auditd | grep -q "active (running)"
}

# 启动服务
start_service() {
	echo "正在启动 auditd 服务..."
	systemctl start auditd
}

ensure_auditd_enabled_and_active() {
	# 确保 auditd 服务启用
	if ! check_enabled; then
		enable_service
		if ! check_enabled; then
			echo "启用 auditd 服务失败."
			exit 1
		else
			echo "启用 auditd 服务成功."
		fi
	else
		echo "auditd 服务已启用."
	fi

	# 确保 auditd 服务运行
	if ! check_active; then
		start_service
		if ! check_active; then
			echo "启动 auditd 服务失败."
			exit 1
		else
			echo "启动 auditd 服务成功."
		fi
	else
		echo "auditd 服务已运行."
	fi
}

# 添加 --self-test 兼容参数
while [[ "$#" -gt 0 ]]; do
	case "$1" in
		--self-test)
			ensure_auditd_enabled_and_active
			exit $? ;;
		*)
			echo "无效选项: $1"
			echo "仅接受 --self-test 参数, 或不加参数"
			exit 1 ;;
	esac
done


ensure_auditd_enabled_and_active

echo "已确保 auditd 服务启用、运行"
exit 0


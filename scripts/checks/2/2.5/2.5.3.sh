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

# 检查dim软件包配置文件
check_dim_rpm() {
    if ! (yum list installed | grep "dim\." > /dev/null); then
        echo "检测失败: dim软件包未安装"
        return 1
    fi

    if ! (yum list installed | grep "dim_tools\." > /dev/null); then
        echo "检测失败: dim_tools软件包未安装"
        return 1
    fi

    return 0
}

# 检查dim内核模块
check_dim_mod() {
    if ! (lsmod | grep dim_core > /dev/null); then
        echo "检测失败: dim_core未加载"
        return 1
    fi

    if ! (lsmod | grep dim_monitor > /dev/null); then
        echo "检测失败: dim_monitor未加载"
        return 1
    fi

    return 0
}

# 检查dim结果
check_dim_result() {
    if [ "$(cat /sys/kernel/security/dim/ascii_runtime_measurements | wc -l)" -eq 0 ]; then
        echo "检测失败: DIM度量策略未正确配置或未生效"
        return 1
    fi

    return 0
}

# 主逻辑
main() {
    # 依次调用检查函数
    if check_dim_rpm && check_dim_mod && check_dim_result ; then
        echo "检查成功: DIM功能启用且配置正确"
        exit 0
    else
        exit 1
    fi
}

main "$@"


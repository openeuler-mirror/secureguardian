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
# Description: Security Baseline Fix Script for 2.2.1
#
# #######################################################################################
#!/bin/bash

# 功能说明:
# 本脚本用于检查并修复 GRUB 口令保护设置，防止未授权用户修改 GRUB 设置。

# 检测 GRUB 配置文件路径
if [ -d /boot/efi/EFI/openEuler ]; then
    grub_config="/boot/efi/EFI/openEuler/grub.cfg"
    user_config="/boot/efi/EFI/openEuler/user.cfg"
elif [ -d /boot/efi/EFI/kylin ]; then
    grub_config="/boot/efi/EFI/kylin/grub.cfg"
    user_config="/boot/efi/EFI/kylin/user.cfg"
else
    grub_config="/boot/grub2/grub.cfg"
    user_config="/boot/grub2/user.cfg"
fi


# 默认 GRUB 口令
grub_password="password"

# 检查 GRUB 配置文件中是否存在口令保护
check_grub_password() {
    if grep -q "password_pbkdf2" "$grub_config"; then
        echo "GRUB 口令保护已设置。"
        return 0
    else
        echo "GRUB 口令保护未设置，准备修复..."
        return 1
    fi
}

# 修复 GRUB 口令保护
set_grub_password() {
    # 生成口令密文
    password_hash=$(grub-mkpasswd-pbkdf2 <<< "$grub_password" | grep -oP "grub.pbkdf2.sha512.10000\..*")

    # 添加口令设置到 grub.cfg
    echo "password_pbkdf2 root ${password_hash}" >> "$grub_config"
    echo "GRUB2_PASSWORD=${password_hash}" >> "$user_config"
    # 更新 GRUB 配置
    grub2-mkconfig -o "$grub_config"
    echo "已设置 GRUB 口令保护。"
}

# 自测功能
run_self_test() {
    echo "执行自测..."
    check_grub_password
    if [ $? -eq 1 ]; then
        set_grub_password
        echo "自测完成，GRUB 口令保护已修复。"
    fi
}

# 处理命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --self-test)
            run_self_test
            exit 0
            ;;
        *)
            echo "无效的选项: $1"
            exit 1
            ;;
    esac
    shift
done

# 检查并修复 GRUB 口令保护
check_grub_password || set_grub_password



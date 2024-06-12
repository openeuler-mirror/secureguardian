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
# Description: Security Baseline Check Script for 1.1.16
#
# #######################################################################################

# 检测软链接和硬链接保护是否正确配置
check_link_protection() {
  local symlink_protect=$(sysctl fs.protected_symlinks)
  local hardlink_protect=$(sysctl fs.protected_hardlinks)
  
  if [[ "$symlink_protect" == "fs.protected_symlinks = 1" && "$hardlink_protect" == "fs.protected_hardlinks = 1" ]]; then
    echo "软链接和硬链接保护已正确配置。"
    return 0  # 检查通过
  else
    echo "软链接或硬链接保护未正确配置。"
    return 1  # 检查未通过
  fi
}

# 调用检测函数
if check_link_protection; then
  #echo "检查通过，不存在无属主或属组的文件或目录。"
  exit 0  # 检查通过，脚本成功退出
else
  #echo "检查未通过。"
  exit 1  # 检查未通过，脚本以失败退出
fi

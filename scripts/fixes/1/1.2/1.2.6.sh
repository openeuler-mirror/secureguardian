#!/bin/bash
 #######################################################################################
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
# Description: Security Baseline Fix Script for 1.2.6
#
# #######################################################################################

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
  echo "软件类暂无实现自测程序"
  exit 0
fi

# 定义文件路径
repo_dir="/etc/yum.repos.d"
repo_files=("$repo_dir"/*.repo)

# 标记修复是否成功
issue_found=0

# 遍历每个.repo文件并进行修复
for file in "${repo_files[@]}"; do
    echo "正在修复文件: $file"
    
    awk -v file="$file" 'BEGIN { RS=""; FS="\n"; OFS="\n" }
    {
        gpgcheck_found=0;
        for (i=1; i<=NF; i++) {
            # 如果找到 gpgcheck=0，直接修改为 gpgcheck=1
            if ($i ~ /gpgcheck\s*=\s*0/) {
                $i = "gpgcheck=1";
                gpgcheck_found=1;
            } else if ($i ~ /gpgcheck\s*=\s*1/) {
                gpgcheck_found=1;  # 如果已经有 gpgcheck=1，则无需修改
            }
        }
        # 如果启用了仓库且没有找到gpgcheck字段，插入gpgcheck=1
        if (/enabled\s*=\s*1/ && !gpgcheck_found) {
            print "文件 " file " 中的启用仓库未显式设置 gpgcheck=1, 现已修复。";
            $0=$0"\ngpgcheck=1";
            issue_found=1;
        }
    }
    { print $0 > file".tmp" }' "$file"

    # 检查awk命令是否执行成功
    if [[ $? -ne 0 ]]; then
        echo "修复文件 $file 时发生错误。"
        issue_found=1
    else
        # 将临时文件替换为原文件
        mv "$file.tmp" "$file"
    fi
done

# 根据修复结果返回成功或失败
if [[ $issue_found -eq 0 ]]; then
    echo "所有yum源均已正确配置gpgcheck=1。"
    exit 0
else
    echo "修复过程中发生错误，请检查输出。"
    exit 1
fi


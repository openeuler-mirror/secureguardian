#!/bin/bash

# 检测所有启用的yum源是否显式设置了gpgcheck=1
check_yum_repos_gpgcheck() {
    local repo_dir="/etc/yum.repos.d"
    local issue_found=0
    local repo_files=("$repo_dir"/*.repo)

    for file in "${repo_files[@]}"; do
        echo "正在检查文件: $file"
        # 分割文件内容到仓库块，并检查每个启用的仓库是否设置了gpgcheck=1
        awk -v file="$file" 'BEGIN { RS=""; FS="\n" }
        /enabled\s*=\s*1/ {
            gpgcheck_found=0; 
            for (i=1; i<=NF; i++) {
                if ($i ~ /gpgcheck\s*=\s*1/) {
                    gpgcheck_found=1;
                }
            }
            if (!gpgcheck_found) {
                print "文件 " file " 中存在启用的仓库没有显式设置 gpgcheck=1";
                exit 1;
            }
        }' "$file"
        
        if [ $? -ne 0 ]; then
            issue_found=1
        fi
    done

    if [ $issue_found -eq 0 ]; then
        echo "所有启用的yum源都已正确配置了显式的gpgcheck=1。"
    else
        echo "存在未正确配置显式的gpgcheck=1的启用的yum源。"
        return 1
    fi
}

check_yum_repos_gpgcheck
exit $?

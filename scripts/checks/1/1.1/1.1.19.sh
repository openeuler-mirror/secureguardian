#!/bin/bash

# 检查所有用户的.bashrc和.bash_profile是否设置了LD_LIBRARY_PATH
check_users_ld_library_path() {
    #echo "检查所有用户配置中LD_LIBRARY_PATH设置..."
    local issue_found=0

    while IFS=: read -r username _ _ _ _ homedir shell; do
        # 跳过nologin用户
        if [[ "$shell" == */nologin ]]; then
            continue
        fi

        # 忽略不存在的家目录
        if [ ! -d "$homedir" ]; then
            continue
        fi

        # 检查用户家目录下的配置文件
        for file in "$homedir/.bashrc" "$homedir/.bash_profile"; do
            if [ -f "$file" ] && grep -q "LD_LIBRARY_PATH" "$file"; then
                echo "发现在 $file 中设置了 LD_LIBRARY_PATH。"
                issue_found=1
            fi
        done
    done < /etc/passwd

    return $issue_found
}

# 调用检测函数
check_users_ld_library_path

if [ $? -eq 0 ]; then
    echo "LD_LIBRARY_PATH 环境变量设置检查通过，未在用户配置中发现不当设置。"
    exit 0
else
    #echo "LD_LIBRARY_PATH 环境变量设置检查未通过，请根据以上提示进行必要的调整。"
    exit 1
fi


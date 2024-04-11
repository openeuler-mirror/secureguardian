#!/bin/bash

check_polkit_rules() {
    local rule_file="/etc/polkit-1/rules.d/50-default.rules"
    local rule_content
    local non_root_users=()

    if [ ! -f "$rule_file" ]; then
        echo "检测失败: 规则文件不存在: $rule_file"
        return 1
    fi

    # 读取整个规则文件的内容
    rule_content=$(cat "$rule_file")

    # 检查是否有允许非root用户使用pkexec的配置
    if [[ "$rule_content" =~ "unix-user:" ]]; then
        # 通过正则表达式匹配查找所有的unix-user规则
        while read -r line; do
            if [[ "$line" =~ unix-user:([^\"]+) ]]; then
                user_id=${BASH_REMATCH[1]}
                # 检查匹配到的用户ID是否为0或root，如果不是，记录下来
                if [[ "$user_id" != "0" && "$user_id" != "root" ]]; then
                    non_root_users+=("$user_id")
                fi
            fi
        done <<< "$(echo "$rule_content" | grep -o 'unix-user:[^,]*')"

        if [ ${#non_root_users[@]} -gt 0 ]; then
            echo "检测失败: 发现允许非root用户使用pkexec的配置。不合规用户ID/用户名: ${non_root_users[@]}"
            return 1
        else
            echo "检测成功: 未发现允许非root用户使用pkexec的配置。"
            return 0
        fi
    else
        echo "检测成功: 未发现允许非root用户使用pkexec的配置。"
        return 0
    fi
}

check_polkit_rules
exit $?

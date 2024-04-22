#!/bin/bash

# 功能说明:
# 此脚本用于检查所有位于/etc/audit/rules.d/目录下的.rules文件，
# 以确认是否在其中配置了'-e 2'，这代表将审计规则设为不可更改。

check_immutable_audit_rules() {
    local rule_files="/etc/audit/rules.d/*.rules"
    local found=0

    for file in $rule_files; do
        if grep -qE "^\s*-e\s+2$" "$file"; then
            echo "检测成功: 文件 '$file' 中正确配置了 '-e 2'。"
            found=1
            break
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo "检测失败: 在任何.rules文件中未找到 '-e 2' 设置。"
        return 1
    else
        return 0
    fi
}

# 调用函数并根据返回值决定退出状态
if check_immutable_audit_rules; then
    exit 0
else
    exit 1
fi


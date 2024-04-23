#!/bin/bash

# 功能说明:
# 本脚本用于检查系统中提权命令的审计规则配置。
# 提权命令通常设置了SUID或SGID权限，本脚本将验证这些命令是否在auditd审计中被适当监控，
# 以防止潜在的安全风险或滥用。

# 定义函数以检查提权命令的审计规则
function check_privileged_commands_audit() {
    # 定位所有具有SUID或SGID权限的命令
    local privileged_commands=$(find / -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null)

    # 标记变量，用于确定是否所有命令都已设置审计
    local all_set=true

    # 遍历每个命令，检查是否已配置审计规则
    for cmd in $privileged_commands; do
        local audit_rule=$(auditctl -l | grep -F -- "$cmd ")
        if [ -z "$audit_rule" ]; then
            echo "$cmd not set"
            all_set=false
        else
            echo "Audit rule set for $cmd: $audit_rule"
        fi
    done

    # 根据检查结果返回相应值
    if [ "$all_set" = true ]; then
        echo "所有提权命令都已正确配置审计规则。"
        return 0
    else
        echo "一些提权命令缺少审计规则。请根据安全政策配置审计。"
        return 1
    fi
}

# 参数解析
while getopts ":?" opt; do
    case "$opt" in
        \?)
            echo "使用方式: $0"
            echo "无需额外参数，直接运行即可检查所有提权命令的审计规则配置。"
            exit 0
            ;;
        *)
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# 调用函数并处理返回值
if check_privileged_commands_audit; then
    exit 0
else
    exit 1
fi


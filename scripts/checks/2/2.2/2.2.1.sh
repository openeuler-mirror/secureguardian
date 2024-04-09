#!/bin/bash

# 函数：检查密码复杂度设置
check_password_complexity() {
    local minlen=8
    local minclass=3
    local dcredit
    local ucredit
    local lcredit
    local ocredit
    local enforce_for_root

    local check_dcredit=false
    local check_ucredit=false
    local check_lcredit=false
    local check_ocredit=false
    local check_enforce_for_root=true

    while getopts "m:c:d:u:l:o:e:" opt; do
        case $opt in
            m) minlen="$OPTARG";;
            c) minclass="$OPTARG";;
            d) dcredit="$OPTARG"; check_dcredit=true;;
            u) ucredit="$OPTARG"; check_ucredit=true;;
            l) lcredit="$OPTARG"; check_lcredit=true;;
            o) ocredit="$OPTARG"; check_ocredit=true;;
            e) enforce_for_root="$OPTARG"; check_enforce_for_root=true;;
            \?) echo "无效的选项: -$OPTARG" >&2; exit 1;;
        esac
    done

    local pwquality_config="/etc/security/pwquality.conf"
    local pam_files=("/etc/pam.d/system-auth" "/etc/pam.d/password-auth")
    local config_meets_requirements=false

    # 首先检查 /etc/security/pwquality.conf
    if [ -f "$pwquality_config" ]; then
        if check_config "$pwquality_config"; then
            echo "$pwquality_config 配置满足要求，不需要检查其他文件。"
            return 0
        else
            echo "$pwquality_config 配置不满足要求，需要检查其他PAM配置。"
        fi
    else
        echo "警告：配置文件 $pwquality_config 未找到，将检查PAM配置。"
    fi

    # 检查 PAM 配置文件
    for config_file in "${pam_files[@]}"; do
        if ! check_config "$config_file"; then
            echo "$config_file 配置不满足密码复杂度要求。"
            return 1  # 检查未通过
        fi
    done

    echo "所有检查的配置文件均满足密码复杂度要求。"
    return 0  # 检查通过
}

# 函数：检查单个配置文件
check_config() {
    local config_file=$1
    local issues=()

    ! grep -Pq "^(?!#).*minlen\s*=\s*$minlen" "$config_file" && issues+=("最小长度设置不符合要求（应为$minlen）")
    ! grep -Pq "^(?!#).*minclass\s*=\s*$minclass" "$config_file" && issues+=("最小字符类别设置不符合要求（应为$minclass）")

    [[ "$check_dcredit" = true ]] && ! grep -Pq "^(?!#).*dcredit\s*=\s*[-]?$dcredit" "$config_file" && issues+=("数字字符设置不符合要求（应为$dcredit）")
    [[ "$check_ucredit" = true ]] && ! grep -Pq "^(?!#).*ucredit\s*=\s*[-]?$ucredit" "$config_file" && issues+=("大写字符设置不符合要求（应为$ucredit）")
    [[ "$check_lcredit" = true ]] && ! grep -Pq "^(?!#).*lcredit\s*=\s*[-]?$lcredit" "$config_file" && issues+=("小写字符设置不符合要求（应为$lcredit）")
    [[ "$check_ocredit" = true ]] && ! grep -Pq "^(?!#).*ocredit\s*=\s*[-]?$ocredit" "$config_file" && issues+=("特殊字符设置不符合要求（应为$ocredit）")
    [[ "$check_enforce_for_root" = true ]] && ! grep -Pq "^(?!#).*enforce_for_root" "$config_file" && issues+=("未为root用户启用强制密码复杂度要求")

    if [ ${#issues[@]} -eq 0 ]; then
        echo "$config_file 配置满足要求。"
        return 0  # 配置满足要求
    else
        echo "$config_file 中存在以下问题："
        for issue in "${issues[@]}"; do
            echo "- $issue"
        done
        return 1  # 配置不满足要求
    fi
}

# 调用函数并处理返回值
if check_password_complexity "$@"; then
    exit 0  # 检查通过，脚本成功退出
else
    exit 1  # 检查未通过
fi


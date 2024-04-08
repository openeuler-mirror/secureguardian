#!/bin/bash

# 定义可能需要检测的网络嗅探和相关工具列表
sniffing_tools="wireshark netcat tcpdump nmap ethereal tshark hping dsniff ettercap aircrack-ng kismet snort zeek"

# 检测网络嗅探工具的RPM包是否已安装
check_sniffing_tools_rpm() {
    local installed_tools=()

    for tool in $sniffing_tools; do
        if rpm -qa | grep -qiE "^($tool-)"; then
            installed_tools+=($tool)
        fi
    done

    if [ ${#installed_tools[@]} -gt 0 ]; then
        echo "检测不通过。已安装的网络嗅探工具RPM包: ${installed_tools[*]}"
        return 1
    else
        echo "RPM包检测通过。未安装网络嗅探工具。"
        return 0
    fi
}

# 检测是否存在网络嗅探工具的命令
check_sniffing_tools_files() {
    local found_tools=()
    local find_cmd="find / -type f"

    for tool in $sniffing_tools; do
        find_cmd="$find_cmd -o -name $tool"
    done

    find_cmd="$find_cmd 2>/dev/null"

    while IFS= read -r path; do
        if file "$path" | grep -qi "ELF"; then
            found_tools+=("$path")
        fi
    done < <(eval "$find_cmd")

    if [ ${#found_tools[@]} -gt 0 ]; then
        echo "检测不通过。发现安装的网络嗅探工具: ${found_tools[*]}"
        return 1
    else
        echo "文件检测通过。未发现安装的网络嗅探工具。"
        return 0
    fi
}

# 执行检查
check_sniffing_tools_rpm
rpm_check_result=$?

#check_sniffing_tools_files
#file_check_result=$?

# 汇总检查结果
#if [ $rpm_check_result -ne 0 ] || [ $file_check_result -ne 0 ]; then
if [ $rpm_check_result -ne 0 ]; then
    #echo "总检测不通过。存在网络嗅探工具。"
    exit 1
else
    #echo "总检测通过。"
    exit 0
fi


#!/bin/bash

# 检测分区是否已以nosuid方式挂载
check_nosuid_mount() {
    local issue_found=0

    # 读取挂载信息并逐行处理
    while IFS= read -r line; do
        # 获取挂载点和文件系统类型
        local mount_point=$(echo "$line" | awk '{print $3}')
        local fs_type=$(echo "$line" | awk '{print $5}')

        # 排除特定的文件系统类型和特殊挂载点
        if [[ "$fs_type" == "autofs" ]] || [[ "$fs_type" == "hugetlbfs" ]] || [[ "$fs_type" == "rpc_pipefs" ]]; then
            continue
        fi

        # 排除根目录、/boot 和 /boot/efi 分区
        if [[ "$mount_point" == "/" ]] || [[ "$mount_point" == "/boot" ]] || [[ "$mount_point" == "/boot/efi" ]]; then
            continue
        fi

        # 检查未设置nosuid的挂载点
        if [[ "$line" != *"nosuid"* ]]; then
            echo "分区 $mount_point 未以nosuid方式挂载：$line"
            issue_found=1
        fi
    done < <(mount)

    if [ $issue_found -eq 1 ]; then
        return 1  # 存在至少一个问题，检测未通过
    else
        echo "所有关心的分区均已以nosuid方式挂载，或者特殊文件系统和挂载点已被正确排除。"
        return 0  # 所有检测均通过
    fi
}

# 调用检测函数并根据返回值决定输出
if check_nosuid_mount; then
    #echo "检查通过。"
    exit 0
else
    #echo "至少一个指定分区未以nosuid方式挂载。"
    exit 1
fi


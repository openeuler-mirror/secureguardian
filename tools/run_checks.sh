#!/bin/bash

# 定义路径
BASE_DIR="/usr/local/secureguardian"
CONF_DIR="$BASE_DIR/conf"
REPORT_DIR="$BASE_DIR/reports"
BASELINE_DIR="$BASE_DIR/baseline"
TOOLS_DIR="$BASE_DIR/tools"

# 初始化变量
requirements_only=false

# 显示帮助信息的函数
show_usage() {
    echo "用法: $0 [选项]..."
    echo "选项:"
    echo "  -h, --help                  显示帮助信息并退出"
    echo "  -c, --config <配置文件名>   指定要执行的检查配置文件，例如：all_checks.json"
    echo "                               如果不指定，则执行conf目录下的所有配置文件"
    echo "  -r, --requirements-only     仅执行级别为'要求'的检查项"
    echo "示例:"
    echo "  $0                          执行所有检查"
    echo "  $0 -c all_checks.json       只执行all_checks.json配置文件下的检查"
    echo "  $0 -r                       仅执行级别为'要求'的检查项"
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_usage ;;
        -c|--config) 
            shift  # 移除 -c，使 $2 的值 (config.json) 移动到 $1
            config_file="$1"  # 现在 $1=config.json
            shift  # 再次移除，这次是移除 config.json，使 $3 的值 (-r) 移动到 $1
            ;;
        -r|--requirements-only) 
            requirements_only=true 
            shift  # 由于 -r 后面没有参数，这个shift用于结束循环，如果有的话
            ;;
        *) 
            echo "未知选项: $1" >&2; 
            exit 1 
            ;;
    esac
    shift  # 如果-case块内没有显式调用shift，这里保证每次循环结束时都调用一次shift
done

generate_html_report() {
    json_file="$1"
    html_file="${json_file%.json}.html"

    # 计算总检查项数、成功和失败的数量
    total_checks=$(jq '. | length' "$json_file")
    success_count=$(jq '[.[] | select(.status=="成功")] | length' "$json_file")
    fail_count=$(jq '[.[] | select(.status=="失败")] | length' "$json_file")

    requirements_total=$(jq '[.[] | select(.level=="要求")] | length' "$json_file")
    recommendations_total=$(jq '[.[] | select(.level=="建议")] | length' "$json_file")

    requirements_success=$(jq '[.[] | select(.level=="要求" and .status=="成功")] | length' "$json_file")
    requirements_fail=$(jq '[.[] | select(.level=="要求" and .status=="失败")] | length' "$json_file")

    recommendations_success=$(jq '[.[] | select(.level=="建议" and .status=="成功")] | length' "$json_file")
    recommendations_fail=$(jq '[.[] | select(.level=="建议" and .status=="失败")] | length' "$json_file")

    # 获取当前时间
    current_time=$(date +"%Y-%m-%d %H:%M:%S")

    # 打印汇总信息到控制台
    echo "报告生成时间：$current_time"
    echo "总检查项数：$total_checks，成功：$success_count，失败：$fail_count"
    echo "要求 - 总计：$requirements_total，成功：$requirements_success，失败：$requirements_fail"
    echo "建议 - 总计：$recommendations_total，成功：$recommendations_success，失败：$recommendations_fail"

    # 生成HTML文件头部
    cat << EOF > "$html_file"
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <title>检查报告</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f4f4f9; /* 浅灰色背景 */
            color: #333;
        }
        header {
            background-color: #4a90e2; /* 蓝色 */
            color: #ffffff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            text-align: left; /* 左对齐 */
        }
        h1 {
            margin: 0;
            padding-bottom: 10px;
        }
        p {
            margin: 5px 0;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            table-layout: fixed;
            background-color: #ffffff; /* 表格白色背景 */
        }
        th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
            word-wrap: break-word;
        }
        th {
            background-color: #4a90e2; /* 蓝色 */
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .status {
            width: 80px; /* 设置"状态"列的宽度 */
        }
        .id, .level {
            width: 50px; /* 设置"ID"和"级别"列的宽度 */
        }
        .success {
            background-color: #d4edda; /* 成功的背景颜色 */
            color: #155724; /* 成功的文字颜色 */
        }
        .fail {
            background-color: #f8d7da; /* 失败的背景颜色 */
            color: #721c24; /* 失败的文字颜色 */
        }
        .tabs {
            display: flex;
            cursor: pointer;
            margin-bottom: 20px;
            justify-content: flex-start; /* 左对齐 */
            border-bottom: 2px solid #ccc;
        }
        .subtabs {
            display: flex;
            cursor: pointer;
            margin-bottom: 20px;
            justify-content: flex-start; /* 左对齐 */
            border-bottom: 1px solid #ccc;
        }
        .tabcontent {
            display: none;
        }
        .subtabcontent {
            display: none;
        }
        .tablinks, .subtablinks {
            padding: 14px 20px;
            background-color: #e1e8f0; /* 浅蓝灰色 */
            border: 1px solid #ccc;
            border-bottom: none;
            border-radius: 5px 5px 0 0;
            margin-right: 5px;
            font-weight: bold;
            transition: background-color 0.3s ease;
        }
        .tablinks.active, .tablinks:hover, .subtablinks.active, .subtablinks:hover {
            background-color: #4a90e2; /* 蓝色 */
            color: white;
        }
        .tabcontent.active, .subtabcontent.active {
            display: block;
        }
    </style>
</head>
<body>
    <header>
        <h1>检查报告</h1>
        <p>报告生成时间：${current_time}</p>
        <p>总检查项数：${total_checks}，成功：${success_count}，失败：${fail_count}</p>
        <p>要求 - 总检查项数：${requirements_total}，成功：${requirements_success}，失败：${requirements_fail}</p>
        <p>建议 - 总检查项数：${recommendations_total}，成功：${recommendations_success}，失败：${recommendations_fail}</p>
        <p>本报告提供了系统安全检查的详细结果，包括每项检查的状态和相关的详细信息。</p>
    </header>
    <div class="tabs">
        <button class="tablinks" onclick="openTab(event, '初始部署')">初始部署</button>
        <button class="tablinks" onclick="openTab(event, '安全访问')">安全访问</button>
        <button class="tablinks" onclick="openTab(event, '运行和服务')">运行和服务</button>
        <button class="tablinks" onclick="openTab(event, '日志审计')">日志审计</button>
    </div>
EOF

    # 定义类别和子类别
    declare -A subcategories
    subcategories=(
        ["初始部署"]="1.1_文件系统 1.2_软件"
        ["安全访问"]="2.1_账户 2.2_口令 2.3_身份认证 2.4_访问控制 2.5_完整性 2.6_数据安全"
        ["运行和服务"]="3.1_网络 3.2_防火墙 3.3_SSH 3.4_定时任务 3.5_内核 3.6_时间同步"
        ["日志审计"]="4.1_Audit 4.2_Rsyslog"
    )

    # 遍历每个类别和子类别
    for category in "${!subcategories[@]}"; do
        echo "<div id=\"$category\" class=\"tabcontent\">" >> "$html_file"
        echo '<div class="subtabs">' >> "$html_file"
        IFS=' ' read -r -a subcategories_array <<< "${subcategories[$category]}"
        for subcategory in "${subcategories_array[@]}"; do
            subcategory_name="${subcategory#*_}"
            echo "<button class=\"subtablinks\" onclick=\"openSubTab(event, '${category}_${subcategory_name}')\">${subcategory_name}</button>" >> "$html_file"
        done
        echo '</div>' >> "$html_file"
        for subcategory in "${subcategories_array[@]}"; do
            subcategory_name="${subcategory#*_}"
            echo "<div id=\"${category}_${subcategory_name}\" class=\"subtabcontent\">" >> "$html_file"
            echo "    <h3>${subcategory_name}</h3>" >> "$html_file"
            echo '    <table><tr><th class="id">ID</th><th>描述</th><th class="level">级别</th><th class="status">状态</th><th>详情</th></tr>' >> "$html_file"
            
            items=$(jq -r --arg subcategory "${subcategory%%_*}" '[.[] | select(.id | startswith($subcategory)) | [.id, .description, .level, .status, .details]] | .[] | @tsv' "$json_file")
            while IFS=$'\t' read -r id description level status details; do
                class=$(if [[ "$status" == "成功" ]]; then echo "success"; else echo "fail"; fi)
                echo "<tr><td class=\"id\">${id}</td><td>${description}</td><td class=\"level\">${level}</td><td class=\"${class}\">${status}</td><td>${details}</td></tr>" >> "$html_file"
            done <<< "$items"
            
            echo '    </table>' >> "$html_file"
            echo '</div>' >> "$html_file"
        done
        echo '</div>' >> "$html_file"
    done

    # 生成HTML文件尾部
    cat << EOF >> "$html_file"
    <script>
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks, subtablinks, subtabcontent;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";

            // Reset subtablinks and subtabcontent
            subtablinks = document.getElementsByClassName("subtablinks");
            for (i = 0; i < subtablinks.length; i++) {
                subtablinks[i].className = subtablinks[i].className.replace(" active", "");
            }
            subtabcontent = document.getElementsByClassName("subtabcontent");
            for (i = 0; i < subtabcontent.length; i++) {
                subtabcontent[i].style.display = "none";
            }

            // Activate the first subtab of the selected tab
            var firstSubtab = document.getElementById(tabName).getElementsByClassName("subtablinks")[0];
            if (firstSubtab) {
                firstSubtab.click();
            }
        }

        function openSubTab(evt, subTabName) {
            var i, subtabcontent, subtablinks;
            subtabcontent = document.getElementsByClassName("subtabcontent");
            for (i = 0; i < subtabcontent.length; i++) {
                subtabcontent[i].style.display = "none";
            }
            subtablinks = document.getElementsByClassName("subtablinks");
            for (i = 0; i < subtablinks.length; i++) {
                subtablinks[i].className = subtablinks[i].className.replace(" active", "");
            }
            document.getElementById(subTabName).style.display = "block";
            evt.currentTarget.className += " active";
        }

        // 默认打开第一个tab
        document.getElementsByClassName("tablinks")[0].click();
    </script>
</body>
</html>
EOF

    echo "HTML报告已生成: $html_file"
}

execute_checks() {
    local config="$1"
    local json_output="${REPORT_DIR}/$(basename "${config%.json}").results.json"

    echo "开始执行检查..."
    echo "[" > "$json_output"
    local first=true
    
    local filter=".checks[] | select(.enabled == true)"
    if [[ "$requirements_only" == "true" ]]; then
        filter=".checks[] | select(.enabled == true) | select(.level == \"要求\")"

    fi
    jq -c "$filter" "$config" | while read -r check; do
        local id=$(echo "$check" | jq -r '.id')
        local level=$(echo "$check" | jq -r '.level')
        local script=$(echo "$check" | jq -r '.script')
        local description=$(echo "$check" | jq -r '.description')
        local parameters=$(echo "$check" | jq -r '.parameters | join(" ")')

        echo "正在执行检查：$id - $description"

        # 执行检查脚本
        output=$($BASE_DIR/$script $parameters 2>&1)
        local status=$?


        if [[ $status -eq 0 ]]; then
            status="成功"
            echo "检查 $id 执行完成：成功"
        else
            status="失败"
            echo "检查 $id 执行完成：失败"
        fi

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$json_output"
        fi

        output=$(echo "$output" | sed ':a;N;$!ba;s/\n/<br><br>/g') # 将换行转为HTML换行
	output=$(echo "$output" | sed 's/[\x00-\x1F\x7F]//g') #去掉控制字符
	output=$(echo "$output" | sed 's/\r//g')  # 去除所有CR字符	

        echo "{\"id\":\"$id\",\"description\":\"$description\",\"level\": \"$level\",\"status\":\"$status\",\"details\":\"$output\",\"link\":\"$BASELINE_DIR/$id.md\"}" >> "$json_output"
    done
    echo "]" >> "$json_output"

    echo "所有检查执行完成。"
    generate_html_report "$json_output"
}

# 执行检查
if [[ -n "$config_file" && -f "$CONF_DIR/$config_file" ]]; then
    execute_checks "$CONF_DIR/$config_file"
else
    # 如果没有指定配置文件或指定的文件不存在，执行conf目录下的所有配置文件
    for config in "$CONF_DIR"/*.json; do
        execute_checks "$config"
    done
fi

echo "检查完成。报告已生成在 $REPORT_DIR"


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
    html_file="${json_file%.results.json}.html"

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

    # HTML文件头部
    cat << EOF > "$html_file"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>检查报告</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f0f0f0;
            color: #333;
        }
        header {
            background-color: #007bff;
            color: #ffffff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
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
        }
        th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .status {
            width: 100px; /* 设置"状态"列的宽度 */
        }
        .success {
            background-color: #d4edda; /* 成功的背景颜色 */
            color: #155724; /* 成功的文字颜色 */
        }
        .fail {
            background-color: #f8d7da; /* 失败的背景颜色 */
            color: #721c24; /* 失败的文字颜色 */
        }
        .md-content {
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <header>
	<h1>检查报告</h1>
        <p>报告生成时间：${current_time}</p>
        <p>总检查项数：${total_checks},成功：${success_count}，失败：${fail_count}</p>
        <p>要求 - 总检查项数：${requirements_total}, 成功：${requirements_success}, 失败：${requirements_fail}</p>
        <p>建议 - 总检查项数：${recommendations_total}, 成功：${recommendations_success}, 失败：${recommendations_fail}</p>
        <p>本报告提供了系统安全检查的详细结果，包括每项检查的状态和相关的详细信息。</p>	
    </header>    	
	<table>
        <tr>
            <th>ID</th>
            <th>描述</th>
            <th>级别</th>
            <th class="status">状态</th>
            <th>详情</th>
        </tr>
EOF

    # 遍历JSON文件中的每个检查项
    jq -r --arg BASELINE_DIR "$BASELINE_DIR" '.[] | [.id, .description, .level, .status,.details] | @tsv' "$json_file" | while IFS=$'\t' read -r id description level status details; do
	class=$(if [[ "$status" == "成功" ]]; then echo "success"; else echo "fail"; fi)
        echo "<tr><td>${id}</td><td>${description}</td><td>${level}</td><td class=\"${class}\">${status}</td><td>${details}</td></tr>" >> "$html_file"
    done

    # HTML文件尾部
    cat << EOF >> "$html_file"
    </table>
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

        output=$(echo "$output" | sed ':a;N;$!ba;s/\n/<br><br>/g')
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


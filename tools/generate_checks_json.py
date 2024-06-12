#!/usr/bin/env python3

# #######################################################################################
#
# Copyright (c) KylinSoft Co., Ltd. 2024. All rights reserved.
# SecureGuardian is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Security Baseline Check Script for run_checks
#
# #######################################################################################

import json
import re
import os
def parse_markdown(md_file_path):
    checks = []
    if not os.path.exists(md_file_path):
        raise FileNotFoundError("The file does not exist, please make sure the file path is correct.\n")
    with open(md_file_path, 'r', encoding='utf-8') as file:
        current_id = None
        current_description = None
        current_level = None

        for line in file:
            if line.startswith('###'):  # 三级标题，包含 ID 和 Description
                match = re.match(r'###\s*(\d+\.\d+\.\d+)\s+(.*)', line)
                if match:
                    current_id = match.group(1)
                    current_description = match.group(2)
                    current_level = None  # Reset level for each new check
                    print("Found check: {}, {}".format(current_id, current_description))  # 打印找到的检查项

            # 更加健壮的正则表达式来提取级别信息
            level_match = re.search(r'\*\*级别：\*\*\s*(.*)', line.strip())
            if level_match:
                current_level = level_match.group(1).strip()
                print("Level found: {}".format(current_level))  # 打印级别信息

            if current_id and current_description and current_level:
                # 构造脚本路径
                id_parts = current_id.split('.')
                script_path = "scripts/checks/{}/{}/{}.sh".format(id_parts[0], id_parts[1], current_id)
                print("Script path: {}".format(script_path))  # 打印脚本路径

                checks.append({
                    "id": current_id,
                    "description": current_description,
                    "level": current_level,
                    "script": script_path,
                    "enabled": True,
                    "parameters": []
                })
                # 重置变量，准备下一个条目
                current_id = None
                current_description = None
                current_level = None

    return checks

def write_json(checks, json_file_path):
    with open(json_file_path, 'w', encoding='utf-8') as file:
        json.dump({"checks": checks}, file, indent=4, ensure_ascii=False)
        print("Written {} checks to {}".format(len(checks), json_file_path))  # 打印写入的检查数量

md_file_path = '/usr/local/secureguardian/baseline/release/openEuler安全配置基线.md1'
json_file_path = 'all_checks_release.json'
checks = parse_markdown(md_file_path)
write_json(checks, json_file_path)


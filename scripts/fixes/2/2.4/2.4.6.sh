#!/bin/bash
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
# Description: Security Baseline fix Script for 2.4.6
#
# #######################################################################################
# #######################################################################################
# 修复脚本，确保sudoers配置的脚本权限安全
# 修复逻辑：
# - 检查sudoers文件中配置的脚本路径。
# - 如果脚本存在且低权限用户可写，修复其权限（去除低权限用户的写权限）。
# - 保留附加参数，仅针对脚本路径进行权限修复。
# - 支持例外脚本路径，通过参数忽略特定路径。
#
# #######################################################################################

# 使用说明
usage() {
  echo "用法: $0 [-e 脚本路径1,脚本路径2,...] [--self-test]"
  echo "示例: $0 -e /bin/ignored_script.sh,/usr/local/bin/ignored_script.sh"
  echo "默认修复/etc/sudoers中低权限用户可写的脚本。"
  echo "使用--self-test模拟问题场景并验证修复逻辑。"
}

# 初始化参数
EXCLUDE=""
SELF_TEST=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--exceptions)
      EXCLUDE="$2"
      shift 2
      ;;
    --self-test)
      SELF_TEST=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "无效选项: $1"
      usage
      exit 1
      ;;
  esac
done

SUDOERS_FILE="/etc/sudoers"

# 修复sudoers中配置脚本的权限
fix_sudoers_scripts() {
  local exclude_pattern="$1"

  # 备份sudoers文件
  cp "$SUDOERS_FILE" "${SUDOERS_FILE}.bak.$(date +%F_%T)"
  echo "已备份sudoers文件至: ${SUDOERS_FILE}.bak.$(date +%F_%T)"

  # 修复逻辑
  while IFS= read -r line; do
    # 忽略注释和默认配置
    if [[ "$line" =~ ^# ]] || [[ "$line" =~ ^Defaults ]]; then
      continue
    fi

    # 提取命令和参数部分
    command_with_params=$(echo "$line" | awk '{$1=$2=$3=""; sub(/^ +/, ""); print}')
    script_path=$(echo "$command_with_params" | awk '{print $1}')  # 提取第一个字段作为脚本路径
    additional_params=$(echo "$command_with_params" | awk '{$1=""; sub(/^ +/, ""); print}')  # 提取其余参数
    real_path=$(realpath "$script_path" 2>/dev/null)  # 获取真实路径

    # 忽略例外路径
    if [[ ",$exclude_pattern," == *",$real_path,"* ]]; then
      continue
    fi

    # 检查脚本是否存在及其权限
    if [ -f "$real_path" ]; then
      writable=$(find "$real_path" -type f \( -perm -002 -o -perm -020 \) -print)
      if [[ ! -z $writable ]]; then
        chmod o-w "$real_path"
        chmod g-w "$real_path"
        echo "修复完成: 已修复脚本的权限 $real_path"
      fi
    fi
  done < <(grep -E "^\s*[^#;]" "$SUDOERS_FILE")
  echo "修复完成"
}

# 自测功能
self_test() {
  echo "自测: 模拟问题场景。"

  # 创建测试脚本
  local test_script="/tmp/test_sudo_script.sh"
  echo "#!/bin/bash" > "$test_script"
  chmod 666 "$test_script"
  echo "创建测试脚本: $test_script (权限为666)"

  # 添加测试内容到 sudoers 文件
  echo "testuser ALL=(ALL) NOPASSWD: $test_script" >> "$SUDOERS_FILE"
  echo "模拟添加低权限用户可写的脚本到 sudoers 文件"

  # 执行修复
  fix_sudoers_scripts ""

  # 检查修复结果
  if [[ $(stat -c "%a" "$test_script") == "644" ]]; then
    echo "自测成功: 低权限用户可写的脚本权限已修复。"
    # 恢复测试前状态
    rm -f "$test_script"
    sed -i '/testuser ALL=(ALL) NOPASSWD: \/tmp\/test_sudo_script.sh/d' "$SUDOERS_FILE"
    return 0
  else
    echo "自测失败: 未能正确修复低权限用户可写的脚本权限。"
    # 恢复测试前状态
    rm -f "$test_script"
    sed -i '/testuser ALL=(ALL) NOPASSWD: \/tmp\/test_sudo_script.sh/d' "$SUDOERS_FILE"
    return 1
  fi
}

# 主函数
main() {
  if [[ "$SELF_TEST" == true ]]; then
    self_test
    exit $?
  fi

  if [ ! -f "$SUDOERS_FILE" ]; then
    echo "sudoers文件不存在: $SUDOERS_FILE"
    exit 1
  fi

  fix_sudoers_scripts "$EXCLUDE"
  exit 0
}

# 执行主函数
main "$@"


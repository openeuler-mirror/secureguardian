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
# Description: Security Baseline fix Script for 1.1.2
#
# #######################################################################################

# 功能说明:
# 本脚本用于检查并修复系统中存在的空链接文件。空链接文件会浪费系统资源，并可能导致文件信息泄露甚至被篡改。
# 使用此脚本可以删除系统中无效的空链接文件，确保系统安全和资源优化。

# 定义检查并修复空链接文件的函数
fix_empty_links() {
  # 使用 find 命令查找并排除特定目录的空链接文件
  local empty_links=$(find / -path /var -prune -o -path /run -prune -o -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type l ! -exec test -e {} \; -print)
  if [[ ! -z $empty_links ]]; then
    while IFS= read -r link; do
      echo "即将删除空链接文件: $link"
      ls -lrt "$link"
      rm "$link"
      if [[ $? -eq 0 ]]; then
        echo "修复成功: 删除空链接文件 $link"
      else
        echo "修复失败: 无法删除空链接文件 $link"
        return 1
      fi
    done <<< "$empty_links"
    return 0  # 所有空链接文件均删除，返回true
  else
    echo "未找到需要修复的空链接文件。"
    return 0  # 未发现问题，返回true
  fi
}

# 自测部分
self_test() {
  # 创建测试环境
  mkdir -p /tmp/testdir
  ln -s /nonexistent /tmp/testdir/emptylink1
  ln -s /nonexistent /tmp/testdir/emptylink2

  echo "自测: 创建了以下空链接文件"
  ls -lrt /tmp/testdir/emptylink1
  ls -lrt /tmp/testdir/emptylink2

  # 运行修复函数
  fix_empty_links

  # 清理测试环境
  rm -rf /tmp/testdir
}

# 检查是否是自测模式
if [[ "$1" == "--self-test" ]]; then
  self_test
  exit $?
else
  # 调用修复函数并处理返回值
  fix_empty_links
  exit $?
fi


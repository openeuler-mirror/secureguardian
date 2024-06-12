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
# Description: Security Baseline Check Script for 3.2.10
#
# #######################################################################################

# 显示用法
show_usage() {
  echo "Usage: $0 [-i ipv4|ipv6|both] [-p protocol] [-c chain]"
  echo "  -i  指定检测的IP版本：ipv4、ipv6或both，默认为both"
  echo "  -p  指定要检测的协议：tcp、udp、icmp，默认检查所有"
  echo "  -c  指定要检测的链：INPUT、OUTPUT，默认检查所有"
}

# 检测iptables规则
check_iptables_rules() {
  local ip_version=$1
  local protocol=$2
  local chain=$3
  local cmd_ipv4="iptables"
  local cmd_ipv6="ip6tables"
  local failed=0
  local cmd
  local protocols
  local chains

  # 设置默认参数
  [[ -z "$protocol" ]] && protocols=("tcp" "udp" "icmp") || protocols=("$protocol")
  [[ -z "$chain" ]] && chains=("INPUT" "OUTPUT") || chains=("$chain")

  check_rules() {
 	 local cmd=$1
 	 local version=$2
 	 local protocol=$3
 	 local chain=$4

 	 echo "检查 $version $protocol $chain..."
 	 # 根据协议和链生成状态匹配模式
 	 local state_match="state (NEW,)?ESTABLISHED"
 	 [[ "$chain" == "INPUT" ]] && state_match="state ESTABLISHED"

 	 # 检查规则
 	 local rules_found=0
 	 local line
 	 while IFS= read -r line; do
 	   if [[ $line =~ $protocol && $line =~ $state_match ]]; then
 	     let rules_found++
 	   fi
 	 done < <($cmd -L $chain -n --line-numbers)

 	 if [[ $rules_found -eq 0 ]]; then
 	   echo "检测失败: $version $chain 链中未找到任何符合 $protocol 协议的规则。"
 	   let failed++
 	 else
 	   echo "找到符合条件的 $protocol 规则 $rules_found 条。"
 	 fi

 	 return $failed
	}

  for prot in "${protocols[@]}"; do
    for ch in "${chains[@]}"; do
      if [[ "$ip_version" == "ipv4" || "$ip_version" == "both" ]]; then
        check_rules "$cmd_ipv4" "IPv4" "$prot" "$ch"
      fi
      if [[ "$ip_version" == "ipv6" || "$ip_version" == "both" ]]; then
        check_rules "$cmd_ipv6" "IPv6" "$prot" "$ch"
      fi
    done
  done

  return $failed
}

# 主逻辑
ip_version="both"  # 默认检查IPv4和IPv6
protocol=""       # 默认为空，检查所有协议
chain=""          # 默认为空，检查所有链

# 解析命令行参数
while getopts ":i:p:c:?" opt; do
  case $opt in
    i) ip_version=$OPTARG ;;
    p) protocol=$OPTARG ;;
    c) chain=$OPTARG ;;
    ?) show_usage
       exit 0 ;;
    *) show_usage
       exit 1 ;;
  esac
done

# 调用函数并处理返回值
if check_iptables_rules "$ip_version" "$protocol" "$chain"; then
  echo "所有规则检查通过。"
  exit 0
else
  echo "部分或全部规则检查未通过。"
  exit 1
fi


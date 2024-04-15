#!/bin/bash

show_usage() {
  echo "使用方法: $0 [-i ipv4|ipv6|both] [-h]"
  echo "  -i  指定IP版本进行检查：ipv4、ipv6或both，默认为both"
  echo "  -h  显示帮助信息"
}

debug_print() {
  echo "$1"
}

check_ipv4_loopback() {
  local ruleset=$(nft list ruleset)
  debug_print "完整规则集: $ruleset"

  local ipv4_input_lo=$(echo "$ruleset" | grep -P ".*iif\s+\"lo\"\s+accept")

  local ipv4_input_drop=$(echo "$ruleset" | grep -P ".*iif\s+!=\s+\"lo\"\s+ip\s+saddr\s+127\.0\.0\.0/8\s+drop")

  local ipv4_output=$(echo "$ruleset" | grep -P ".*ip\s+saddr\s+127\.0\.0\.0/8\s+accept")

  [ -z "$ipv4_input_lo" ] && echo "检测失败: IPv4 loopback 策略配置不正确 - 未正确配置 'lo' 接口接收规则"
  [ -z "$ipv4_input_drop" ] && echo "检测失败: IPv4 loopback 策略配置不正确 - 未正确配置从非 'lo' 接口丢弃源地址为 127.0.0.0/8 的报文"
  [ -z "$ipv4_output" ] && echo "检测失败: IPv4 loopback 策略配置不正确 - 未正确配置源地址为 127.0.0.0/8 的报文接受规则"

  [[ -z "$ipv4_input_lo" || -z "$ipv4_input_drop" || -z "$ipv4_output" ]] && return 1
  echo "IPv4 loopback 策略检查通过。"
  return 0
}

# 同样的修改适用于IPv6检查和both检查
check_ipv6_loopback() {
  local ruleset=$(nft list ruleset)
  debug_print "完整规则集: $ruleset"
  
  local ipv6_input_lo=$(echo "$ruleset" | grep -P  ".*iif\s+\"lo\"\s+accept")
  local ipv6_input_drop=$(echo "$ruleset" | grep -P ".*iif\s+!=\s+\"lo\"\s+ip6\s+saddr\s+::1\s+drop")
  local ipv6_output=$(echo "$ruleset" | grep -P ".*ip6\s+saddr\s+::1\s+accept")

  [ -z "$ipv6_input_lo" ] && echo "检测失败: IPv6 loopback 策略配置不正确 - 未正确配置 'lo' 接口接收规则"
  [ -z "$ipv6_input_drop" ] && echo "检测失败: IPv6 loopback 策略配置不正确 - 未正确配置从非 'lo' 接口丢弃源地址为 ::1 的报文"
  [ -z "$ipv6_output" ] && echo "检测失败: IPv6 loopback 策略配置不正确 - 未正确配置源地址为 ::1 的报文接受规则"

  [[ -z "$ipv6_input_lo" || -z "$ipv6_input_drop" || -z "$ipv6_output" ]] && return 1
  echo "IPv6 loopback 策略检查通过。"
  return 0
}

check_both_loopback() {
  check_ipv4_loopback
  local ipv4_result=$?
  check_ipv6_loopback
  local ipv6_result=$?

  if [[ $ipv4_result -eq 0 && $ipv6_result -eq 0 ]]; then
    echo "IPv4和IPv6 loopback 策略检查均通过。"
    return 0
  else
    return 1
  fi
}

ip_version="both"
while getopts ":i:h" opt; do
  case $opt in
    i) ip_version=$OPTARG ;;
    h) show_usage
       exit 0 ;;
    *) show_usage
       exit 1 ;;
  esac
done

case $ip_version in
  ipv4) check_ipv4_loopback ;;
  ipv6) check_ipv6_loopback ;;
  both) check_both_loopback ;;
  *)    echo "无效的IP版本参数 - '$ip_version'"
        show_usage
        exit 1 ;;
esac

if [ $? -eq 0 ]; then
  echo "检查成功:所有 loopback 策略检查通过。"
  exit 0
else
  echo "检查失败:至少一个 loopback 策略检查未通过。"
  exit 1
fi


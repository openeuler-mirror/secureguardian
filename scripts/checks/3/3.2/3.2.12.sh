#!/bin/bash

# 检查链的默认策略
check_default_policy() {
  local chain_name=$1
  local expected_policy=$2
  local ruleset=$(nft list ruleset)
  
  # 使用awk匹配指定链的策略
  local policy=$(echo "$ruleset" | awk -v chain="$chain_name" -v policy="$expected_policy" '
    $0 ~ "chain " chain ".*{" {
      recording = 1
    }
    recording && /}/ {
      recording = 0
      exit
    }
    recording && /policy/ {
      if ($0 ~ "policy " policy ";") {
        found = 1
      }
    }
    END {
      if (found) 
        print "yes"
      else 
        print "no"
    }')

  if [[ "$policy" == "yes" ]]; then
    echo "$chain_name 链已正确配置为默认 $expected_policy 策略。"
    return 0
  else
    echo "检测失败: $chain_name 链未配置为默认 $expected_policy 策略。"
    return 1
  fi
}

# 执行检查
check_chains() {
  local failed=0
  check_default_policy "input" "drop" || failed=1
  check_default_policy "output" "drop" || failed=1
  check_default_policy "forward" "drop" || failed=1
  return $failed
}

# 根据检查结果输出最终状态
if check_chains; then
  echo "所有基础链的策略检查通过。"
  exit 0
else
  echo "至少一个基础链的策略检查未通过。"
  exit 1
fi


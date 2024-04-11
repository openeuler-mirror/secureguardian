#!/bin/bash

# 使用说明
usage() {
  echo "用法: $0 [/?] [-e 脚本路径1,脚本路径2,...]"
  echo "示例: $0 -e /bin/ignored_script.sh,/usr/local/bin/ignored_script.sh"
  echo "/? 显示这个帮助信息。"
  echo "-e 指定例外脚本路径，这些脚本将被忽略不检查。"
}

# 解析参数
EXCLUDE=""

while getopts ":he:?" opt; do
  case ${opt} in
    e )
      EXCLUDE="$OPTARG"
      ;;
    \? | h )
      usage
      exit 0
      ;;
    * )
      echo "无效选项: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

# 检查sudoers中配置的脚本权限
#!/bin/bash

# 其他初始化和函数定义...

check_sudoers_scripts() {
  local exclude_pattern=$EXCLUDE
  local script_path
  local real_path
  local writable
  local check_failed=0

  # 修改循环，使用进程替换而不是管道
  while IFS= read -r line; do
    command_with_params=$(echo "$line" | awk -F "NOPASSWD:" '{print $2}' | xargs)
    script_path=$(echo "$command_with_params" | cut -d' ' -f1)
    real_path=$(realpath "$script_path" 2>/dev/null) # 避免不存在的文件报错

    if [[ ",$exclude_pattern," == *",$real_path,"* ]]; then
      continue
    fi

    if [ -f "$real_path" ]; then
      writable=$(find "$real_path" -type f \( -perm -002 -o -perm -020 \) -print)
      if [[ ! -z $writable ]]; then
        echo "检测失败: 低权限用户可写的sudo配置脚本: $writable"
        check_failed=1
      fi
    else
      echo "检测注意: sudo配置的命令不存在，无法检查权限: $script_path"
    fi
  done < <(grep -E "^\s*[^#;].*NOPASSWD:\s*" /etc/sudoers) # 这里使用了进程替换

  if [ "$check_failed" -eq 1 ]; then
    echo "检测不成功: 发现低权限用户可写的sudo配置脚本。"
    return 1
  else
    echo "检测成功: 未发现低权限用户可写的sudo配置脚本。"
    return 0
  fi
}


# 主函数
main() {
  if [ ! -f "/etc/sudoers" ]; then
    echo "sudoers文件不存在: /etc/sudoers"
    exit 1
  fi

  check_sudoers_scripts
  exit $?
}

main "$@"


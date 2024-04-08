#!/bin/bash

# 默认例外用户为root，可以通过命令行参数 -e 指定额外的例外用户
EXCEPTIONS=("root")

# 接收命令行参数
while getopts 'e:' OPTION; do
  case "$OPTION" in
    e)
      IFS=',' read -r -a CUSTOM_EXCEPTIONS <<< "$OPTARG"
      EXCEPTIONS+=("${CUSTOM_EXCEPTIONS[@]}") # 添加自定义的例外用户
      ;;
    ?)
      echo "使用方法: $0 [-e 用户列表]"
      echo "例子: $0 -e user1,user2"
      exit 1
      ;;
  esac
done

# 检查用户Home目录函数
check_user_home_directories() {
    # 从/etc/passwd获取用户和Home目录
    while IFS=: read -r user _ uid _ _ home shell; do
        # 检查用户是否为例外
        if [[ " ${EXCEPTIONS[*]} " =~ " ${user} " ]]; then
            echo "跳过例外用户: $user"
            continue
        fi

        # 跳过非登录用户
        if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" || "$shell" == "/usr/sbin/nologin" ]]; then
            echo "跳过非登录用户: $user"
            continue
        fi

        # 检查Home目录是否存在
        if [ ! -d "$home" ]; then
            echo "检测失败: 用户 $user 的Home目录 $home 不存在。"
            return 1
        fi

        # 检查Home目录的属主是否为用户自己
        home_owner=$(stat -c '%U' "$home")
        if [ "$home_owner" != "$user" ]; then
            echo "检测失败: 用户 $user 的Home目录 $home 属主不是 $user。"
            return 1
        fi
    done < <(awk -F':' '$3>=1000 && $3!=65534 {print $0}' /etc/passwd)

    echo "检测成功: 所有用户的Home目录都存在且属主正确。"
    return 0
}

# 调用检查函数并处理返回值
if check_user_home_directories; then
    exit 0
else
    exit 1
fi


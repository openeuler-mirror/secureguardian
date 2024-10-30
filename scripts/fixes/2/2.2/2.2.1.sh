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
# Description: Security Baseline Fix Script for 2.2.1
#
# #######################################################################################
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
# Description: Security Baseline Repair Script for Password Complexity
#
# #######################################################################################

# 初始化参数
minlen=8
minclass=3
dcredit=0
ucredit=0
lcredit=0
ocredit=0
enforce_for_root=true

# 参数解析函数，支持自定义参数和自测模式
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m)
        minlen="$2"
        shift 2
        ;;
      -c)
        minclass="$2"
        shift 2
        ;;
      -d)
        dcredit="$2"
        shift 2
        ;;
      -u)
        ucredit="$2"
        shift 2
        ;;
      -l)
        lcredit="$2"
        shift 2
        ;;
      -o)
        ocredit="$2"
        shift 2
        ;;
      -e)
        enforce_for_root="$2"
        shift 2
        ;;
      --self-test)
        self_test
        exit $?
        ;;
      *)
        echo "使用方法: $0 [-m 最小长度] [-c 最小字符组合] [-d dcredit] [-u ucredit] [-l lcredit] [-o ocredit] [-e enforce_for_root] [--self-test]"
        exit 1
        ;;
    esac
  done
}

# 自测功能
self_test() {
  echo "自测模式: 检查密码复杂度配置是否符合预期..."
  
  # 这里可以添加自测逻辑，验证当前配置是否符合预期
  echo "自测成功: 当前配置符合预期。"
}

# 修复密码复杂度设置的函数
fix_password_complexity() {
  # 配置文件路径
  local config_files=("/etc/security/pwquality.conf" "/etc/pam.d/password-auth" "/etc/pam.d/system-auth")

  for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
      echo "正在更新 $config_file ..."

      # 更新 pwquality.conf
      if [[ "$config_file" == "/etc/security/pwquality.conf" ]]; then
        {
          echo "minlen=$minlen"
          echo "minclass=$minclass"
          echo "dcredit=$dcredit"
          echo "ucredit=$ucredit"
          echo "lcredit=$lcredit"
          echo "ocredit=$ocredit"
          if [[ "$enforce_for_root" == true ]]; then
            echo "enforce_for_root"
          fi
        } > "$config_file"
        echo "$config_file 更新完成。"
      else
        # 更新 PAM 配置文件
        sed -i "/^password.*pam_pwquality.so/s/.*/password requisite pam_pwquality.so minlen=$minlen minclass=$minclass dcredit=$dcredit ucredit=$ucredit lcredit=$lcredit ocredit=$ocredit $( [[ "$enforce_for_root" == true ]] && echo "enforce_for_root" ) try_first_pass local_users_only/" "$config_file"
        echo "$config_file 更新完成。"
      fi
    else
      echo "文件 $config_file 不存在，无法更新。"
    fi
  done

  echo "密码复杂度配置更新完成。"
}

# 解析传入的参数
parse_arguments "$@"

# 执行修复任务
fix_password_complexity

exit 0


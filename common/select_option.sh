#!/bin/bash

select_option() {
  choices=("$@") # 将选项数组声明为全局变量
  selected=0     # 初始化选择索引

  while true; do
    clear
    for index in "${!choices[@]}"; do
      if [ $index -eq $selected ]; then
        printf "\033[31m> ${choices[$index]}\033[0m\n" # 高亮显示选中的选项
      else
        echo "  ${choices[$index]}"
      fi
    done

    read -n1 -s key # 读取单个按键并保持输入的隐私

    case "$key" in
    A) # 上箭头
      if [ $selected -gt 0 ]; then
        selected=$((selected - 1))
      fi
      ;;
    B) # 下箭头
      if [ $selected -lt $((${#choices[@]} - 1)) ]; then
        selected=$((selected + 1))
      fi
      ;;
    "") # 回车键
      break
      ;;
    esac
  done
  # 打印最终结果日志
  selected_option="${choices[$selected]}"
  echo "最终选择：$selected_option"
}

# 定义选项数组
options=("Option 1" "Option 2" "Option 3" "Option 4")

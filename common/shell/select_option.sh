#!/bin/bash

# A sample script for select function of shell scripts

function select_single_option {
  local choices=("$@")
  local selected=0
  echo "${choices[@]}"

  while true; do
    clear
    for index in "${!choices[@]}"; do
      if [ $index -eq $selected ]; then
        printf "\033[31m> ${choices[$index]}\033[0m\n"
      else
        echo "  ${choices[$index]}"
      fi
    done

    read -N1 -r -s key

    case "$key" in
    A) # up
      if [ $selected -gt 0 ]; then
        selected=$((selected - 1))
      fi
      ;;
    B) # down
      if [ $selected -lt $((${#choices[@]} - 1)) ]; then
        selected=$((selected + 1))
      fi
      ;;
    $'\n') # enter  $'\x0a'
      break
      ;;
    esac
  done
  selected_option="${choices[$selected]}"
  echo "You choose $selected_option"
}

function select_multiple_option {
  local choices=("$@")
  local current_index=0
  local selected=() # selected index
  choices=("${choices[@]}" "next")
  echo "${selected[*]}"

  while true; do
    clear
    for index in "${!choices[@]}"; do
      if [[ ${selected[*]} =~ ${choices[index]} ]]; then
        if [[ $index -eq $current_index ]]; then
          printf "\033[32m > ${choices[$index]}\033[0m\n"
        else
          printf "\033[32m ${choices[$index]}\033[0m\n"
        fi
      else
        if [[ $index -eq $current_index ]]; then
          printf "\033[31m > ${choices[$index]}\033[0m\n"
        else
          echo " ${choices[index]}"
        fi
      fi
    done

    read -N1 -s key
    case "$key" in
    A)
      if [ $current_index -gt 0 ]; then
        current_index=$((current_index - 1))
      fi
      ;;
    B)
      if [ $current_index -lt $((${#choices[@]} - 1)) ]; then
        current_index=$((current_index + 1))
      fi
      ;;
    $'\n') # enter  $'\x0a'
      # select done, exit
      if [[ $current_index -eq $((${#choices[@]} - 1)) ]]; then
        break
      else
        # remove item
        if [[ ${selected[*]} =~ ${choices[$current_index]} ]]; then
          selected=("${selected[@]/${choices[current_index]}/}")
        else
          selected=("${selected[@]}" "${choices[current_index]}")
        fi
      fi
      ;;
    esac
  done
  echo "You choose：${selected[*]}"
}

options=("Option 1" "Option 2" "Option 3" "Option 4")
select_single_option "${options[@]}"

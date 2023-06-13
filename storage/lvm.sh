#!/bin/bash
# set -xe

pvs=($(sudo pvs | sed "1d" | awk '{print $1}'))
vgs=($(sudo vgs | sed "1d" | awk '{print $1}'))
lvs=($(sudo lvs | sed "1d" | awk '{print $1}'))
new_disk= # new disk path
vg_name=
lv_name=
operation=

echo "current physical volums: ${pvs}"
echo "current volumn groups: ${vgs}"
echo "current logic volums: ${lvs}"
read -p "Please specify a new disk: " new_disk

if [[ -z ${new_disk} ]]; then
  echo "New disk not specified, exit ..."
  exit 127
fi
sudo pvcreate ${new_disk}
echo "pv for disk ${new_disk} created successfully"

read -p "Please specify volumn group: " vg_name
if [[ ! $vg_name =~ $vgs ]]; then
  echo "Cannot find specified Volumn Group"
  exit 127
fi
sudo vgextend $vg_name $new_disk

read -p "Please specify the logic volumn that you want to increase: " lv_name
read -p "Please specify the capacity operation (e.g., +1G, -1G): " operation

sudo lvextend -L ${operation} /dev/${vg_name}/${lv_name}

echo "Make logic volumn ${lv_name} of ${vg_name} ${operation} successfully"

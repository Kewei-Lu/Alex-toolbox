#!/bin/bash

# Create VM based on Bridge mode
VM_NAME=$1
VM_IP_ADDR=$2
BRIDGE_NAME=$3
IF_MAC_ADDR=52:54:00:ee:6f:ae

echo "VM Name: ${VM_NAME}"
echo "VM IP: ${VM_IP_ADDR}"
echo "Linux Bridge Name: ${BRIDGE_NAME}"

# Bridge Network setup
sudo brctl addbr $BRIDGE_NAME

range=($(echo "$VM_IP_ADDR" | sed 's/\./ /g'))
GW_RANGE="${range[0]}.${range[1]}.${range[2]}"
GW_IP="${GW_RANGE}.1"

sudo ifconfig $BRIDGE_NAME ${GW_RANGE}.1/24 up

if ! sudo iptables -t nat -L | grep -q ${GW_RANGE}.0/24; then
  sudo iptables -t nat -A POSTROUTING -s ${GW_RANGE}.0/24 ! -d ${GW_RANGE}.0/24 -j MASQUERADE
  sudo iptables -I FORWARD -s ${GW_RANGE}.0/24 -j ACCEPT
  sudo iptables -I FORWARD -d ${GW_RANGE}.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
fi

# Change paras for this section

MEM_SIZE=8192
CPU_NUM=30
DISK1_SIZE=60G

if [ -z $VM_NAME ]; then
  echo "No vm name."
  exit
fi

mydir=$(pwd)

if [ -e $VM_NAME ]; then
  rm -rf $VM_NAME
fi

mkdir -p $VM_NAME

# Basic Config init
cat >$VM_NAME/$VM_NAME.init.config <<EOF
#cloud-config
hostname: HOSTNAME_TO_SET
manage_etc_hosts: true
users:
  - name: user1
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, docker
    home: /home/user
    shell: /bin/bash
    lock_passwd: false
disable_root: false
ssh_pwauth: True
chpasswd:
  list: |
    user1:user1
  expire: False
write_files:
  - path: /etc/apt/apt.conf
    content: |
      Acquire::http::proxy "http://child-prc.intel.com:913/";
      Acquire::https::proxy "http://child-prc.intel.com:913/";
bootcmd:
  - grep -ri "proxy" /etc/profile && echo "yes" || (echo "export http_proxy=\"http://child-prc.intel.com:913\""|sudo tee -a /etc/profile && echo "export https_proxy=\"http://child-prc.intel.com:913\""|sudo tee -a /etc/profile && echo "export no_proxy=\"*.intel.com,intel.com,localhost,127.0.0.1,192.168.0.0/16,10.10.10.0/24\""|sudo tee -a /etc/profile)
packages:
  - openssh-server
  - python-minimal
  - unzip
  - make
power_state:
  delay: now
  mode: reboot
  message: reboot reboot
  timeout: 1
  condition: True
EOF

# Network config
cat >$VM_NAME/$VM_NAME.network.config <<EOF
version: 2
ethernets:
  enp1s0:
    wakeonlan: true
    dhcp4: false
    nameservers:
      addresses: [10.248.2.1]
    addresses: [$VM_IP_ADDR/24]  # change the address every time a new vm is created
    gateway4: ${GW_IP}
EOF

cat >$VM_NAME/$VM_NAME.nic.config.xml <<EOF
<interface type='bridge'>
  <mac address='52:54:00:f9:bf:32'/>
  <source bridge='${BRIDGE_NAME}'/>
  <model type='virtio'/>
  <driver name='vhost' queues='8'/>
  <address type='pci' domain='0x0000' bus='0x10' slot='0x01' function='0x0'/>
</interface>
EOF

cat >$VM_NAME/$VM_NAME.qat.config.xml <<EOF
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    <address domain='0x0000' bus='0x4d' slot='0x00' function='0x0'/>
  </source>
  <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
</hostdev>
EOF

sudo qemu-img create -b $mydir/ubuntu-20.04-server-cloudimg-amd64.img -f qcow2 -F qcow2 $VM_NAME/$VM_NAME-0.img $DISK1_SIZE
qemu-img info $VM_NAME/$VM_NAME-0.img

sed -i -e "s,HOSTNAME_TO_SET,$VM_NAME," $VM_NAME/$VM_NAME.init.config

cloud-localds -v --network-config=$VM_NAME/$VM_NAME.network.config $VM_NAME/$VM_NAME.seed.img $VM_NAME/$VM_NAME.init.config

sudo virt-install --name $VM_NAME \
  --virt-type kvm --memory $MEM_SIZE --vcpus $CPU_NUM \
  --boot hd,menu=on \
  --disk path=$VM_NAME/$VM_NAME.seed.img,device=cdrom \
  --disk path=$VM_NAME/$VM_NAME-0.img,device=disk \
  --os-type Linux --os-variant ubuntu20.04 \
  --network model=virtio,bridge=${BRIDGE_NAME},mac=$IF_MAC_ADDR

# while ! ping -c 1 -W 1 $VM_IP_ADDR; do
#   echo "Wait vm boot up..."
#   sleep 5
# done
echo "Vm booted up..."
sudo virsh dumpxml $VM_NAME >$VM_NAME/$VM_NAME.xml
NIC_LINE_NUMBER=$(cat $VM_NAME/$VM_NAME.xml | grep -nE "$IF_MAC_ADDR" | awk '{print $1}' | cut -d ':' -f 1)
sed -i ''"$NIC_LINE_NUMBER"'a <driver name='"'"'vhost'"'"' queues='"'"'8'"'"'/>' $VM_NAME/$VM_NAME.xml
sudo virsh define $VM_NAME/$VM_NAME.xml
sudo virsh attach-device $VM_NAME --file $VM_NAME/$VM_NAME.qat.config.xml --config
# while [ $(sudo virsh list | grep $VM_NAME | awk '{print $3}')x == "running"x ]; do
#   echo "Wait vm shut down..."
#   sudo virsh shutdown $VM_NAME
#   sleep 2
# done
# echo "vm shutdown"
# sudo virsh start $VM_NAME
# echo "vm restart"

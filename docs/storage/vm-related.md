

## Make a VM image as a device and mount it to a specific path in rootfs

It is commonly known that a VM image can be mounted to a mount point by `mount -p loop <Mount point> <Image Name>`. 
It is also the most commonly way to start a vm with image in a specific path like `virt-install --disk /path-to-image`

In this way, the image file is also included in root fs, which actually increase some performance cost. (TODO: what exactly is the cost? don't know...)

As an alternative, one can make the image as a bare device, and the VM will directly use that "device". So it will not be wrapped by filesystem of the host machine, which increase performance.

To achieve this, we leverage LVM to create a LV for each image, and copy the image to that "LV device".
```bash
pvcreate ...
vgcreate ...
lvcreate lv1 <vg_name>

# After lvcreate, a new path will be created under /dev/vg_name/ and /dev/mapper/vg_name-lv_name TODO: what is the difference between them?
# And we shall copy the image using "dd" but not cp for the reason that dd is copied by block, but cp is copied by bytes 
# but anyway, I think in this case you can also use cp. However, if you are using RAID, which means lv will have multiple strips, it will be better to use dd with bs=blocksize
# dd can also test network speed: `dd if=/dev/zero bs=4096 count=1048576 | ssh user@host.tld 'cat > /dev/null'`
# cp is dd without much more options
dd if=<image_path_in_host_fs> of=</dev/vg_name/lv_name> bs=4M/8M
virt-install --disk=/dev/vg_name/lv_name

```

### Performance benchmark

A simple benchmark is easy to implement to discover resource usage and performance difference between using `file system` and `device`.

2 VMs cloned from same base image of SPECvirt are prepared and will be booted up from `file system` and `device` separately.

Host info:
* CPU: Intel(R) Xeon(R) Platinum 8455C 2 sockets
* Memory: 256G (16G * 16)
* Disk: 3 * nvme(1.5T) RAID5

* Bootup command with `appserver1`
```bash
cd /home/specvirt/specvirt-scripts/scripts/build_vm && /home/specvirt/specvirt-scripts/scripts/build_vm/vfio-pci-bind.rb 98:10.0 && numactl -m 0 -N 0 /usr/libexec/qemu-kvm -machine pc-q35-6.2,accel=kvm,usb=off,vmport=off,dump-guest-core=off -enable-kvm -cpu host,migratable=off,+invtsc,-vmx,+tsc-deadline,pmu=off -smp 3 -m 6144 -mem-prealloc -mem-path /dev/hugepages1G -device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x2 -device pcie-root-port,port=0x11,chassis=2,id=pci.2,bus=pcie.0,addr=0x2.0x1 -device pcie-root-port,port=0x12,chassis=3,id=pci.3,bus=pcie.0,addr=0x2.0x2 -device pcie-root-port,port=0x13,chassis=4,id=pci.4,bus=pcie.0,addr=0x2.0x3 -device pcie-root-port,port=0x14,chassis=5,id=pci.5,bus=pcie.0,addr=0x2.0x4 -device pcie-root-port,port=0x15,chassis=6,id=pci.6,bus=pcie.0,addr=0x2.0x5 -device pcie-root-port,port=0x16,chassis=7,id=pci.7,bus=pcie.0,addr=0x2.0x6 -device pcie-root-port,port=0x17,chassis=8,id=pci.8,bus=pcie.0,addr=0x2.0x7 -device virtio-blk-pci,scsi=off,bus=pci.3,drive=hd,write-cache=on,bootindex=1 -drive if=none,id=hd,file=/home/specvirt/images/appserver1,format=raw,cache=none -object rng-random,id=objrng0,filename=/dev/urandom -device virtio-rng-pci,rng=objrng0,id=rng0,bus=pci.7,addr=0x0 -name appserver01.console,process=appserver01.console,debug-threads=on -device vfio-pci,host=0000:98:10.0 -display none --nic none --rtc base="2020-05-27T00:00:00" --serial stdio --monitor null -kernel /boot/vmlinuz.guest -initrd /boot/initramfs.guest -append "root=/dev/mapper/rhel-root resume=/dev/mapper/rhel-swap ro rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb selinux=0 audit=0 elevator=deadline clocksource=kvm_clock highres=off ipv6.disable=1 nowatchdog intel_idle.max_cstate=0 processor.max_cstate=1 cgroup_disable=memory,cpu,blkio net.ifnames=0 biosdevname=0 console=ttyS0"
```
* Bootup command with `appserver2`

```bash
cd /home/specvirt/specvirt-scripts/scripts/build_vm && /home/specvirt/specvirt-scripts/scripts/build_vm/vfio-pci-bind.rb 98:10.2 && numactl -m 0 -N 0 /usr/libexec/qemu-kvm -machine pc-q35-rhel7.6.0,accel=kvm,usb=off,vmport=off,dump-guest-core=off -enable-kvm -cpu host,migratable=off,+invtsc,-vmx,+tsc-deadline,pmu=off -smp 3 -m 6144 -mem-prealloc -mem-path /dev/hugepages1G -device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x2 -device pcie-root-port,port=0x11,chassis=2,id=pci.2,bus=pcie.0,addr=0x2.0x1 -device pcie-root-port,port=0x12,chassis=3,id=pci.3,bus=pcie.0,addr=0x2.0x2 -device pcie-root-port,port=0x13,chassis=4,id=pci.4,bus=pcie.0,addr=0x2.0x3 -device pcie-root-port,port=0x14,chassis=5,id=pci.5,bus=pcie.0,addr=0x2.0x4 -device pcie-root-port,port=0x15,chassis=6,id=pci.6,bus=pcie.0,addr=0x2.0x5 -device pcie-root-port,port=0x16,chassis=7,id=pci.7,bus=pcie.0,addr=0x2.0x6 -device pcie-root-port,port=0x17,chassis=8,id=pci.8,bus=pcie.0,addr=0x2.0x7 -device virtio-blk-pci,scsi=off,bus=pci.3,drive=hd,write-cache=on,bootindex=1 -drive if=none,id=hd,file=/dev/disk1/appserver2,format=raw,cache=none -object rng-random,id=objrng0,filename=/dev/urandom -device virtio-rng-pci,rng=objrng0,id=rng0,bus=pci.7,addr=0x0 -name appserver02.console,process=appserver02.console,debug-threads=on -device vfio-pci,host=0000:98:10.2 -display none --nic none --rtc base="2020-05-27T00:00:00" --serial stdio --monitor null -kernel /boot/vmlinuz.guest -initrd /boot/initramfs.guest -append "root=/dev/mapper/rhel-root resume=/dev/mapper/rhel-swap ro rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb selinux=0 audit=0 elevator=deadline clocksource=kvm_clock highres=off ipv6.disable=1 nowatchdog intel_idle.max_cstate=0 processor.max_cstate=1 cgroup_disable=memory,cpu,blkio net.ifnames=0 biosdevname=0 console=ttyS0"
```

```bash
# appserver1 for file system, appserver2 for device 
# Create a volume group
vgcreate <vg_name> <pv_name>
lvcreate -L 56320M -n appserver2 <vg_name>

# In appserver1
dd if=/dev/zero of=test1 bs=8k count=102400 oflag=direct
#dd if=/dev/zero of=test1 bs=8k count=102400 oflag=direct
# 102400+0 records in
# 102400+0 records out
# 838860800 bytes (839 MB, 800 MiB) copied, 13.8131 s, 60.7 MB/s

# In appserver2
dd if=/dev/zero of=test1 bs=8k count=102400 oflag=direct
# dd if=/dev/zero of=test1 bs=8k count=102400 oflag=direct
# 102400+0 records in
# 102400+0 records out
# 838860800 bytes (839 MB, 800 MiB) copied, 5.33592 s, 157 MB/s
```

In host OS, check CPU usage with IO wait

```bash
# check with sar -u 2 10
# %iowait when starting appserver1
~= 0.32
# %iowait when starting appserver2
~= 0.09
```




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
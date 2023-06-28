## Write Hole in RAID

基于奇偶校验(parity)的RAID条带化写入缺乏原子性(atomicity)，如果在写入某一条带数据，而奇偶校验位没有更新时掉电. 重启后, 奇偶校验段无法感知数据部分已经变化，当需要恢复数据时，就无法正常进行恢复。
![WriteHole](http://www.ssdfans.com/wp-content/uploads/2016/06/062616_1238_RAIDWrite1.jpg)


## VROC
* Container: 一个容器表示一组硬盘，但是这一组硬盘可以不用来只组一个raid，而是可以多个不同种类的raid。
比如， Container A 有4个disk，先创建一个container，然后在这个container中用这4块盘创建一个raid5。 
然后我还可以再container A中用这4块盘创建一个raid1，同样的盘，但是在内部隔离blocksize。

```bash
mdadm -C /dev/md/imsm0 /dev/nvme[1-3]n1 -n 3 -e imsm  # create a container
mdadm -C /dev/md0 /dev/md/imsm0 -n3 -l5 --consistency-policy=ppl -z 100G  # create a raid5 array at /dev/md0 with 3 disks /dev/md/imsm0  and 100G
mdadm -C /dev/md1 /dev/md/imsm0 -n3 -l5 --consistency-policy=ppl -z 100G  # create another raid5 array at /dev/md1 with 3 disks in /dev/md/imsm0 and 100G
```

### mdadm
#### Config
```bash
mdadm -E -s > /etc/mdadm.conf
```

#### Status Check
```bash
mdadm -D /dev/md/mdxxx  # check raid array status
mdadm -E /dev/nvmexxx  # check member drive status

# Monitor
mdmon /dev/mdxxx

# start as a daemon
mdmon --monitor --scan --daemonise --syslog

# Systemd
systemctl status mdmonitor
```

#### Assembly
Assembly means "activating" the RAID array.
```bash
mdadm -A -s # read default config at `/etc/mdadm.conf` 
mdadm -A /dev/md/md0 -e imsm /dev/<member drives>
```
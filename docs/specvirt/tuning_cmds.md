```bash
#grub 
mitigations=off

```

echo never > /sys/kernel/mm/transparent_hugepage/defrag

cat /sys/module/kvm/parameters/halt_poll_ns

qemu-kvm: -cpu host,kvm-hint-dedicated=on
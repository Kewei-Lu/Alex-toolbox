## Remove a PV from VG
* (**Important!** If the pv is used by a lv) should reduce `file system size` first, then reduce `lv size`, then reduce `pv` from `vg`.
> When increasing the size, `lvextend` will increase the `lv size` , then increasing `file system size`automatically. But for decreasing, it will not help downgrade the file size. 
* move data from the pv to be removed to other pvs `pvmove <pv_to_remove> <another_pv>`

* What if removing `pv` without decreasing `filesystem size`?
  * The error will report 
    ```bash
    The filesystem size (according to the superblock) is 2217984 blocks
    The physical size of the device is 1048576 blocks
    ```
  * Solution: re-increase the size of `lv`
    ```bash
    vgextend <vg_name> <pv_name> # re-join the pv
    lvextend/lvresize -L <original size> <lv_name># re-size lv to original size
    e2fsck -f <lv_name>  # repair
    resize2fs <lv_name> <wanted_size> # resize fs
    lvresize -L <wanted_size> <lv_name> # resize lv
    pvmove ... 
    vgreduce ... 
    ```
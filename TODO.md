To do list
==========

- [ ] split OM_mkfs into OM_mkfs, OM_mount, OM_cpvol
- [ ] Add a `ooom-check.sh` script
- [ ] Add a `ooom-prepare.sh` script
- [ ] Add support for non-apt-get systems
- [ ] Add a `ooom.parted` file:
<pre>
# default to 100%, ext2 filesystem:
/dev/sde1
# default to ext2 file system:
/dev/sdd1 33%
/dev/sdd2 67%
# complete usage:
/dev/sdb1 100% ext2 set 1 boot on
/dev/sdc1 100% swap
</pre>
- [ ] Support for other file systems: `zfs`, etc.
See https://github.com/zfsonlinux/pkg-zfs/wiki/HOWTO-install-Ubuntu-to-a-Native-ZFS-Root-Filesystem
See https://github.com/zfsonlinux/pkg-zfs/issues/52

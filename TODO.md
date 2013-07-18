To do list
==========

- [ ] Add suport for comments in ooom.fstab
- [ ] Add a `ooom-check.sh` script
- [ ] Add a `ooom-prepare.sh` script
- [ ] Add support for non-apt-get systems
- [ ] Add a `ooom.parted` file:
<pre>
/dev/sdb1 100% ext2 set 1 boot on
/dev/sdc1 100% swap
/dev/sdd1 33%
/dev/sdd2 67%
</pre>
- [ ] Research: `sudo /etc/init.d/unattended-upgrades stop`
- [ ] Support for other file systems: `zfs`, etc.
See https://github.com/zfsonlinux/pkg-zfs/wiki/HOWTO-install-Ubuntu-to-a-Native-ZFS-Root-Filesystem
See https://github.com/zfsonlinux/pkg-zfs/issues/52

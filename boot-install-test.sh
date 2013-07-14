#!/usr/bin/env bash

set -vxe

parted -s /dev/sdb mklabel msdos mkpart primary ext2 1M 100% set 1 boot on
mkfs.ext2 /dev/sdb1
mkdir /mnt/boot
mount /dev/sdb1 /mnt/boot
cd /boot
find . -depth -print0 | cpio --null --sparse --make-directories --pass-through --verbose /mnt/boot
cd /
umount /mnt/boot
mv /boot /boot.orig
mkdir /boot
echo "/dev/sdb1 /boot ext2 ro 0 2" >>/etc/fstab
mount /dev/sdb1 /boot
parted /dev/sda set 1 boot off
grub-install /dev/sdb
update-grub
reboot

#error: file '/boot/grub/i386-pc/normal.mod' not found.
#grub rescue>
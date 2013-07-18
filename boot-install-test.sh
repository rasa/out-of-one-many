#!/usr/bin/env bash

set -vxe

echo >/etc/rc.local
UUID="00000000-0000-0000-0000-000000000000"
parted -s /dev/sdb mklabel msdos mkpart primary ext2 1M 100% set 1 boot on
mkfs.ext2 -U $UUID /dev/sdb1
mkdir -p /mnt/boot/boot
mount /dev/sdb1 /mnt/boot
cd /boot
find . -depth -print0 | cpio --null --sparse --make-directories --pass-through --verbose /mnt/boot/boot
cd /
echo "/dev/sdb1 /boot ext2 ro 0 2" >/etc/fstab.new
cat /etc/fstab >>/etc/fstab.new
mv /etc/fstab /etc/fstab.orig
mv /etc/fstab.new /etc/fstab
mv /boot /boot.orig
parted /dev/sda set 1 boot off
umount /mnt/boot
mkdir /boot
mount /dev/sdb1 /boot
cd /boot
echo GRUB_TIMEOUT=-1 >>/etc/default/grub
echo GRUB_DISABLE_LINUX_UUID=true >>/etc/default/grub
echo GRUB_DEVICE=/dev/sdb1 >>/etc/default/grub
echo GRUB_DEVICE_UUID=$UUID >>/etc/default/grub
#update-initramfs -u
#dpkg-reconfigure grub-pc
#update-grub
#grub-install --root-directory=/mnt/boot --boot-directory=/mnt/boot/boot --recheck /dev/sdb
#reboot

#error: file '/boot/grub/i386-pc/normal.mod' not found.
#grub rescue>

#Per http://askubuntu.com/questions/142300/how-to-fix-error-unknown-filesystem-grub-rescue and
#http://askubuntu.com/questions/197833/recovering-from-grub-rescue-crash ,
#I was able to recover via:

#grub rescue>  set prefix=(hd0,1)/boot.orig/grub
#grub rescue>  insmod linux
#grub rescue>  linux (hd0,1)/boot.orig/vmlinuz-2.6.32-33-generic
#grub rescue>  initrd (hd0,1)/boot.orig/initrd.img-2.6.32-33-generic
#grub rescue>  boot

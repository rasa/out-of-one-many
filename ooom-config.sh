#!/usr/bin/env bash

set -o allexport

OOOM_ZERO_DISKS="/ /var"

OOOM_GRUB_VOL=

# doesn't work yet:
#OOOM_GRUB_VOL=/boot
# in ooom.fstab:
#/dev/sdb /boot ext2 ro 0 1

#OOOM_FINAL_COMMAND="shutdown -P now"

OOOM_FINAL_COMMAND=""

OOOM_PACKAGE_MAP="
	btrfs,btrfs-tools
	cramfs,util-linux
	exfat,exfat-utils
	ext2,e2fsprogs
	ext3,e2fsprogs
	ext4,e2fsprogs
	ntfs,ntfs-3g
	reiserfs,reiser4progs
	vfat,dosfstools
	xfs,xfsprogs
"

OOOM_FSTAB=ooom.fstab

OOOM_INSTALL="apt-get -q -q -y --allow-unauthenticated --no-install-recommends install"

OOOM_LOG_DIR=/.ooom-logs

# eof

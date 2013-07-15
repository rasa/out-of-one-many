#!/usr/bin/env bash

set -o allexport

OOOM_ZERO_DISKS="/"

# doesn't work yet:
OOOM_GRUB_VOL=

# eventually, we should be able to:
#OOOM_GRUB_VOL=/boot
# in ooom.fstab:
#/dev/sdb /boot ext2 ro 0 1

OOOM_PACKAGE_MAP="
	btrfs,btrfs-tools
	exfat,exfat-utils
	exfat,fuse-exfat
	ext2,e2fsprogs
	ext3,e2fsprogs
	ext4,e2fsprogs
	ntfs,ntfs-3g
	reiser4,reiser4progs
	vfat,dosfstools
	xfs,xfsprogs
"

OOOM_INSTALL="apt-get -q -q -y --allow-unauthenticated --no-install-recommends install"

OOOM_LOG_DIR=/.ooom-logs

if [ -f "ooom-custom.fstab" ]
then
	OOOM_FSTAB=ooom-custom.fstab
else
	OOOM_FSTAB=ooom.fstab
fi

if [ -f "ooom-custom-config.sh" ]
then
	. ./ooom-custom-config.sh
fi

# eof

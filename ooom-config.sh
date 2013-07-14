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
	vfat,dosfstools
	ext2,e2fsprogs
	ext3,e2fsprogs
	ext4,e2fsprogs
	xfs,xfsprogs
"

OOOM_FSTAB=ooom.fstab

OOOM_APT_GET="apt-get -q -q -y --allow-unauthenticated --no-install-recommends"

OOOM_LOG_DIR=/.ooom-logs

# eof

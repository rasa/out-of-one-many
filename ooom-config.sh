#!/usr/bin/env bash

set -o allexport

# set to no value (or unset) to not remove the original directories that remain on the source volume:
OOOM_REMOVE_BACKUPS=1

# list the directories mounted on partitions to zero the free space on
# NOTE: This appears to only work on ext2/ext3/ext4 formatted partitions
OOOM_ZERO_DISKS="/"

# doesn't work yet:
OOOM_GRUB_VOL=

# eventually, we will be able to:
#OOOM_GRUB_VOL=/boot
# and add to ooom.fstab:
#/dev/sdb /boot ext2 ro 0 1

OOOM_CHMODS="
/tmp=1777
"

OOOM_UUID=00000000-0000-0000-0000-000000000000

OOOM_PACKAGE_MAP="
	btrfs,btrfs-tools
	exfat,exfat-utils
	exfat,fuse-exfat
	ext2,e2fsprogs
	ext3,e2fsprogs
	ext4,e2fsprogs
	jfs,jfsutils
	ntfs,ntfs-3g
	reiser4,reiser4progs
	vfat,dosfstools
	xfs,xfsprogs
"

OOOM_INSTALL="apt-get -q -q -y --allow-unauthenticated --no-install-recommends install"

# directory to create log files
# make sure NOT to place this on a volume that will be moving
OOOM_LOG_DIR=/.ooom-logs

OOOM_MOUNT=/mnt/ooom

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

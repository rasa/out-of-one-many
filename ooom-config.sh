#!/usr/bin/env bash

set -o allexport

# set to 1 to remove the original directories that remain on the source volume
# leave blank to disable
OOOM_REMOVE_BACKUPS=1

# list the directories mounted on partitions to zero the free space on
# NOTE: This appears to only work on ext2/ext3/ext4 formatted partitions
# separate the directory names by spaces (for example: OOOM_ZERO_DISKS="/ /var /opt")
# leave blank to disable
OOOM_ZERO_DISKS="/"

# list the volume to mark as bootable
# leave blank to disable
OOOM_BOOT_VOL=/boot

# list the volume to install/update grub on
# leave blank to disable
OOOM_UPDATE_GRUB=

# the command to execute when processing is complete
# To poweroff, use: shutdown -P now
# To reboot  , use: shutdown -r now
# leave blank to disable
OOOM_EXIT_COMMAND="shutdown -P now"

# volume UUID mask, the last two characters will be replaced with the unique value, starting from 01
# Setting OOOM_UUID to
# 00000000-0000-0000-0000-000000000000,
# would create disks with UUIDs of
# 00000000-0000-0000-0000-000000000001
# 00000000-0000-0000-0000-000000000002
# etc.
# leave blank to disable
OOOM_UUID=

# map of file system and package to install for that file system
# leave blank to disable
OOOM_PACKAGE_MAP="
	btrfs,btrfs-tools
	exfat,exfat-utils
	ext2,e2fsprogs
	ext3,e2fsprogs
	ext4,e2fsprogs
	jfs,jfsutils
	ntfs,ntfs-3g
	reiser4,reiser4progs
	vfat,dosfstools
	xfs,xfsprogs
"

# command to install packages
# required
OOOM_INSTALL="apt-get --quiet --quiet --yes --allow-unauthenticated --no-install-recommends install"

# directory to create log files
# make sure to place this on a volume that is not being moved
# required
OOOM_LOG_DIR=/.ooom-logs

# directory to mount volumes
# the directory should not already exist, as it will be deleted when ooom is done
# required
OOOM_MOUNT=/mnt/ooom

# temporary directory to create files
# required
OOOM_TMPDIR=/tmp

if [ -f "ooom-custom.fstab" ]
then
	OOOM_FSTAB=ooom-custom.fstab
else
	OOOM_FSTAB=ooom.fstab
fi

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

if [ -f "$OOOM_DIR/ooom-custom-config.sh" ]
then
	echo Running $OOOM_DIR/ooom-custom-config.sh ...

	. $OOOM_DIR/ooom-custom-config.sh
fi

# eof

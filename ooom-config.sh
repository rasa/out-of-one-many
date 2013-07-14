#!/usr/bin/env bash

set -o allexport

# format:
# device,directory[,vfstype[,options]]
# examples:
# /dev/sdd,/home
# /dev/sde,/mnt/sde,ext3
# /dev/sdf,/mnt/sdf,xfs,rw,noatime

# @todo use an fstab like file:

# /dev/sdd /home
# /dev/sde /opt
# /dev/sdf /srv
# /dev/sdh /usr/local
# /dev/sdi /var
# /dev/sdj /var/lib/mysql
# /dev/sdk /var/log
# /dev/sdg /tmp
# /dev/sdl /mnt/sdl btrfs
# /dev/sdm /mnt/sdm ext2
# /dev/sdn /mnt/sdn ext3
# /dev/sdo /mnt/sdo ext4
# /dev/sdp /mnt/sdp vfat
# /dev/sdq /mnt/sdq xfs rw,noatime

DISK_MAP="
/dev/sdd,/home
/dev/sde,/opt
/dev/sdf,/srv
/dev/sdh,/usr/local
/dev/sdi,/var
/dev/sdj,/var/lib/mysql
/dev/sdk,/var/log
/dev/sdg,/tmp
/dev/sdl,/mnt/sdl,btrfs
/dev/sdm,/mnt/sdm,ext2
/dev/sdn,/mnt/sdn,ext3
/dev/sdo,/mnt/sdo,ext4
/dev/sdp,/mnt/sdp,vfat
/dev/sdq,/mnt/sdq,xfs,rw,noatime
"

ZERO_DISK_MAP="/ /var"

MBR_DEV=/dev/sda

GRUB_VOL=

SWAP_DEV=/dev/sdc

# doesn't work yet:
#GRUB_VOL=/boot
#DISK_MAP="
#/dev/sdb,/boot,ext2,ro
#"

#FINAL_COMMAND="shutdown -P now"

FINAL_COMMAND=""

LOG_DIR=/.ooom-logs

APT_GET="apt-get -q -q -y --allow-unauthenticated --no-install-recommends"

BOOT1_PACKAGES="
	btrfs-tools
	dosfstools
	e2fsprogs
	xfsprogs
"

# @todo

PACKAGE_MAP="
btrfs,btrfs-tools
vfat,dosfstools
ext2,e2fsprogs
ext3,e2fsprogs
ext4,e2fsprogs
xfs,xfsprogs
"

# eof

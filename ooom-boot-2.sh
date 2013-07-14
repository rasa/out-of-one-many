#!/usr/bin/env bash

set -o xtrace

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# for debugging only:
#set | sort

. "$SCRIPT_DIR/ooom-config.sh"

# for debugging only:
#set | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

if [ ! -d "$LOG_DIR" ]
then
	mkdir -p "$LOG_DIR"
fi

pushd "$LOG_DIR"

echo '#############################################################'
echo === 2100-remove-backup-directories
echo '#############################################################'

for entry in $DISK_MAP
do
	dev=${entry%%,*}
	volfmtopt=${entry#*,}
	vol=${volfmtopt%%,*}

	if [ ! -b "$dev" ]
	then
		echo === Device not found: "$dev"
		continue
	fi

	if [ ! -d "$vol" ]
	then
		echo === Directory not found: $vol
		continue
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	if [ -d "$mnt" ]
	then
		rmdir "$mnt"
	fi

	if [ ! -d $vol.orig ]
	then
		echo === Directory not found: $vol.orig
		continue
	fi

	echo === Executing: rm -fr $vol.orig

	rm -fr $vol.orig

	echo === \$?=$?
done

echo '#############################################################'
echo === 3990-zero-free-space
echo '#############################################################'

# Zero out the free space to save space in the final image

for vol in $ZERO_DISK_MAP
do
#	dev=${entry%%,*}
#	volfmtopt=${entry#*,}
#	vol=${volfmtopt%%,*}
#	fmtopt=${volfmtopt#*,}
#	fmt=${fmtopt%%,*}

#	if [ ! -b "$dev" ]
#	then
#		echo === Device not found: "$dev"
#		continue
#	fi

	if [ ! -d "$vol" ]
	then
		echo === Directory not found: "$vol"
		continue
	fi

#	if echo "$fmt" | egrep -vq '\b(ext2|ext3|ext4)\b'
#	then
#		echo === Skipping format: "$fmt" as it does not support sparse files
#		continue
#	fi

	if [ "$vol" != "/" ]
	then
		vol=$vol/
	fi

	zero=${vol}ZERO_FREE_SPACE

	echo === Executing: dd if=/dev/zero of=$zero bs=1M

	dd if=/dev/zero of=$zero bs=1M

	echo === \$?=$?

	echo === Executing: rm -f $zero

	rm -f $zero

	echo === \$?=$?
done

# eof

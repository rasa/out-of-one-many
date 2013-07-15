#!/usr/bin/env bash

OM_rmbackup()
{
	dev=$1
	vol=$2

	if [ "$vol" = "none" ]
	then
		return 0
	fi

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		return 1
	fi

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: "$vol"
		return 1
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	if [ -d "$mnt" ]
	then
		rmdir "$mnt"

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
	fi

	if [ ! -d "$vol.orig" ]
	then
		echo Error: Directory not found: "$vol.orig"
		return 1
	fi

	rm -fr $vol.orig

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
}

set -o xtrace

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

cd "$OOOM_DIR"

# for debugging only:
#set | sort

. "$OOOM_DIR/ooom-config.sh"

# for debugging only:
#set | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

FSTAB_FILE=$OOOM_DIR/$OOOM_FSTAB

if [ ! -f "$FSTAB_FILE" ]
then
	echo File not found: $FSTAB_FILE
	exit 1
fi

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	OM_rmbackup "$dev" "$vol"
done < $FSTAB_FILE

# Zero out the free space to save space in the final image

for vol in $OOOM_ZERO_DISKS
do
	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: "$vol"
		continue
	fi

	if [ "$vol" != "/" ]
	then
		vol=$vol/
	fi

	zero=${vol}ZERO_FREE_SPACE

	dd if=/dev/zero of=$zero bs=1M

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	rm -f $zero

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
done

# eof

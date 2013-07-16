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

	mnt=$OOOM_MOUNT/$voldir

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

	echo Removing "$vol.orig" ...

	rm -fr $vol.orig

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
}

OM_chmod()
{
	vol=$1
	mode=$2

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: "$vol"
		return 1
	fi

	if [ -z "$mode" ]
	then
		echo Error: Invalid mode: "$mode"
		return 1
	fi

	echo Setting rights on $vol to $mode ...

	chmod $mode $vol
}

#set -o xtrace

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

cd "$OOOM_DIR"

# for debugging only:
#set | sort

. "$OOOM_DIR/ooom-config.sh"

# for debugging only:
#set | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

if [ -f "$OOOM_DIR/ooom-custom-boot-2-start.sh" ]
then
	"$OOOM_DIR/ooom-custom-boot-2-start.sh"
fi

OOOM_FSTABS=$OOOM_DIR/$OOOM_FSTAB

if [ ! -f "$OOOM_FSTABS" ]
then
	echo File not found: $OOOM_FSTABS
	exit 1
fi

for volmode in $OOOM_CHMODS
do
	vol=${volmode%%=*}
	mode=${volmode#*=}

	OM_chmod "$vol" "$mode"
done

if [ "$OOOM_REMOVE_BACKUPS" ]
then
	tac $OOOM_FSTABS | while IFS=$' \t' read -r -a var
	do
		dev=${var[0]}
		vol=${var[1]}

		OM_rmbackup "$dev" "$vol"
	done
fi

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

	echo Zeroing free space on $vol ...

	dd if=/dev/zero of=$zero bs=1M

	rm -f $zero
done

if [ -d "$OOOM_MOUNT" ]
then
	rmdir "$OOOM_MOUNT"
fi

if [ -f "$OOOM_DIR/ooom-custom-boot-1-end.sh" ]
then
	"$OOOM_DIR/ooom-custom-boot-1-end.sh"
fi

# eof

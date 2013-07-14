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

for package in $BOOT1_PACKAGES
do
	$APT_GET install $package

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
done

mkswap()
{
	swapoff -a -v

	perl -pi.orig -e 's/^(.*none\s+swap\s+sw.*)$/#\1/;' /etc/fstab

	parted -s $1 mklabel msdos mkpart primary linux-swap 1M 100%

	swap_partition=${1}1

	if [ ! -b "$swap_partition" ]
	then
		echo Error: Device not found: "$swap_partition"
	else
		mkswap -L swap -f $swap_partition

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		echo "Appending \"$swap_partition none swap sw 0 0\"" to /etc/fstab

		echo "$swap_partition none swap sw 0 0" >>/etc/fstab

		swapon -v $swap_partition

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		swapon -a -v

		swapon -s
	fi
}

if [ -b "$SWAP_DEV" ]
then
	mkswap "$SWAP_DEV"
fi

for entry in $DISK_MAP
do
	dev=${entry%%,*}
	volfmtopt=${entry#*,}
	vol=${volfmtopt%%,*}

	fmtopt=${volfmtopt#*,}

	if [ "$fmtopt" = "$vol" ]
	then
		fmtopt=
	fi

	fmt=${fmtopt%%,*}
	opt=${fmtopt#*,}

	if [ "$opt" = "$fmt" ]
	then
		opt=
	fi

	if [ -z "$fmt" ]
	then
		fmt=ext4
	fi

	if [ -z "$opt" ]
	then
		opt=defaults
	fi

	dev1=${dev}1

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		continue
	fi

#	if [ "$vol" = "/boot" ]
#	then
#		fmt=ext2
#		opt=ro
#	fi

	parted -s $dev mklabel msdos mkpart primary ext2 1M 100%

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	if [ ! -b "$dev1" ]
	then
		echo Error: Device not found: $dev1
		continue
	fi

	mkfs.$fmt $dev1

	if [ "$?" -eq "0" ]
	then
		echo Appending "$dev1 $vol $fmt $opt 0 2" to /etc/fstab

		echo "$dev1 $vol $fmt $opt 0 2" >>/etc/fstab

		if [ ! -d "$vol" ]
		then
			mkdir -p "$vol"

			EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
		fi

		if [ "$vol" = "/tmp" ]
		then
			echo Skipping volume $vol
			continue
		fi

		voldir=`echo $vol | tr -d /`

		mnt=/mnt/$voldir

		mode=0755

		mkdir -p --mode $mode $mnt

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		mount -t $fmt -o $opt $dev1 $mnt

		if [ "$?" -gt "0" ]
		then
			rmdir $mnt
		else
			chmod $mode $mnt

			EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

			pushd $vol

				find . -depth -print0 | cpio --null --sparse --make-directories --pass-through $mnt

				EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

			popd
		fi
	fi
done

for entry in $DISK_MAP
do
	dev=${entry%%,*}
	volfmtopt=${entry#*,}
	vol=${volfmtopt%%,*}

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		continue
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	if [ -d "$mnt" ]
	then
		if [ "$vol" = "/tmp" ]
		then
			mode=1777
		else
			mode=0755
		fi

		mv -f $vol $vol.orig

		mkdir -p --mode $mode $vol

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		chmod $mode $vol

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		if [ "$vol" = "/tmp" ]
		then
			continue
		fi

		umount $mnt

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

		mount $vol

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
	fi
done

for entry in $DISK_MAP
do
	dev=${entry%%,*}
	volfmtopt=${entry#*,}
	vol=${volfmtopt%%,*}

	if [ "$vol" != "$GRUB_VOL" ]
	then
		continue
	fi

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		continue
	fi

	if [ ! -b "$MBR_DEV" ]
	then
		echo Error: Device not found: "$MBR_DEV"
		continue
	fi

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: $vol
		continue
	fi

	grub-install --boot-directory=$GRUB_VOL $MBR_DEV

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	update-grub

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
done

# eof

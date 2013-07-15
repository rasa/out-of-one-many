#!/usr/bin/env bash

OM_mkswap()
{
	dev=$1
	vol=$2

	if [ "$vol" != "none" ]
	then
		echo Error: Invalid swap volume name: "$vol"
		return 1
	fi

	swapoff -a -v

	perl -pi.orig -e 's/^(.*none\s+swap\s+.*)$/#\1/;' /etc/fstab

	parted -s $dev mklabel msdos mkpart primary linux-swap 1M 100%

	swap_partition=${1}1

	if [ ! -b "$swap_partition" ]
	then
		echo Error: Device not found: "$swap_partition"
		return 1
	fi

	mkswap -L swap -f $swap_partition

	if [ "$?" -gt 0 ]
	then
		echo Error: mkswap failed to create swap on $swap_partition
		return 1
	fi

	echo "Appending \"$swap_partition none swap sw 0 0\"" to /etc/fstab

	echo "$swap_partition none swap sw 0 0" >>/etc/fstab

	swapon -v $swap_partition

	if [ "$?" -gt 0 ]
	then
		echo Error: swapon failed to mount $swap_partition
		return 1
	fi

	swapon -a -v

	swapon -s
}

OM_mkfs()
{
	dev=$1
	vol=$2
	fmt=$3
	opt=$4
	ex1=$5
	ex2=$6

	devn=$dev

	if [ ! -b "$dev" ]
	then
		dev=${devn:0:-1}

	fi

	if [ -z "$vol" ]
	then
		echo Error: Invalid volume: "$vol"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		return 0
	fi

	if [ -z "$fmt" ]
	then
		fmt=ext4
	fi

	if [ -z "$opt" ]
	then
		opt=defaults
	fi

	if [ -z "$ex1" ]
	then
		ex1=0
	fi

	if [ -z "$ex2" ]
	then
		ex2=2
	fi

#	if [ "$vol" = "/boot" ]
#	then
#		fmt=ext2
#		opt=ro
#	fi

	if [ ! -b "$devn" ]
	then
		if [ ! -b "$dev" ]
		then
			echo Error: Device not found: "$dev"
			return 1
		fi

		parted -s $dev mklabel msdos mkpart primary ext2 1M 100%
	fi

	if [ ! -b "$devn" ]
	then
		echo Error: Device not found: "$devn"
		return 1
	fi

	mkfs.$fmt $devn

	if [ "$?" -gt 0 ]
	then
		mkfs.$fmt failed to format $devn
		return 1
	fi

	echo Appending "$devn $vol $fmt $opt $ex1 $ex2" to /etc/fstab

	echo "$devn $vol $fmt $opt $ex1 $ex2" >>/etc/fstab

	if [ ! -d "$vol" ]
	then
		mkdir -p "$vol"
	fi

	if [ ! -d "$vol" ]
	then
		return 1
	fi

	if [ "$vol" = "/tmp" ]
	then
		echo Skipping volume $vol
		return 0
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	mode=0755

	mkdir -p --mode $mode $mnt

	if [ ! -d "$mnt" ]
	then
		return 1
	fi

	mount -t $fmt -o $opt $devn $mnt

	EL=$?

	if [ "$EL" -gt "0" ]
	then
		if [ "$fmt" = "exfat" ]
		then
			$OOOM_INSTALL software-properties-common
			add-apt-repository -y ppa:relan/exfat
			$OOOM_INSTALL exfat-fuse

			mount -t $fmt -o $opt $devn $mnt
			EL=$?
		fi
	fi

	if [ "$EL" -gt "0" ]
	then
		rmdir $mnt
		return 1
	fi

	chmod $mode $mnt

	pushd $vol

	find . -depth -print0 | cpio --null --sparse --make-directories --pass-through $mnt

	popd

	return 0
}

OM_mvvol()
{
	dev=$1
	vol=$2

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		continue
	fi

	if [ -z "$vol" ]
	then
		echo Error: Invalid volume: "$vol"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		return 0
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	if [ ! -d "$mnt" ]
	then
		echo Error: Directory not found: "$mnt"
		return 1
	fi

	if [ "$vol" = "/tmp" ]
	then
		mode=1777
	else
		mode=0755
	fi

	mv -f $vol $vol.orig

	if [ ! -d "$vol.orig" ]
	then
		echo Error: Directory not found: "$vol.orig"
		return 1
	fi

	mkdir -p --mode $mode $vol

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: "$vol"
		return 1
	fi

	chmod $mode $vol

# not needed:
#	if [ "$vol" = "/tmp" ]
#	then
#		return 0
#	fi
#
#	umount $mnt
#
#	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
#
#	mount $vol
#
#	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
}

OM_grubdev()
{
	dev=$1
	vol=$2

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		return 0
	fi

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: "$vol"
		return 1
	fi

	grub-install --boot-directory=$vol "$dev"

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	update-grub

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

if [ -f "$OOOM_DIR/ooom-custom-boot-1-start.sh" ]
then
	"$OOOM_DIR/ooom-custom-boot-1-start.sh"
fi

FSTAB_FILE=$OOOM_DIR/$OOOM_FSTAB

if [ ! -f "$FSTAB_FILE" ]
then
	echo File not found: $FSTAB_FILE
	exit 1
fi

# https://bugs.launchpad.net/ubuntu/+source/ntfs-3g/+bug/1148541

if [ ! -L /sbin/mkfs.ntfs ]
then
	if [ -f /sbin/mkntfs ]
	then
		ln -s /sbin/mkntfs /sbin/mkfs.ntfs
	fi
fi

while IFS=$' \t' read -r -a var
do
	fmt=${var[2]}

	if [ -z "$fmt" ]
	then
		continue
	fi

	for entry in $OOOM_PACKAGE_MAP
	do
		fs=${entry%%,*}
		package=${entry#*,}

		if [ "$fmt" != "$fs" ]
		then
			continue
		fi

		$OOOM_INSTALL $package
	done

done < $FSTAB_FILE

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}
	fmt=${var[2]}
	opt=${var[3]}
	ex1=${var[4]}
	ex2=${var[5]}

	if [ "$fmt" = "swap" ]
	then
		OM_mkswap "$dev" "$vol" "$fmt" "$opt" "$ex1" "$ex2"
		continue
	fi

	OM_mkfs "$dev" "$vol" "$fmt" "$opt" "$ex1" "$ex2"
done < $FSTAB_FILE

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	OM_mvvol "$dev" "$vol"
done < $FSTAB_FILE

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	if [ "$vol" != "$OOOM_GRUB_VOL" ]
	then
		continue
	fi

	echo NOTE: Grub installation not yet implemented, sorry.

#	OM_grubdev "dev" "$vol"
done < $FSTAB_FILE

if [ -f "$OOOM_DIR/ooom-custom-boot-1-end.sh" ]
then
	"$OOOM_DIR/ooom-custom-boot-1-end.sh"
fi

# eof

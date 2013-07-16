#!/usr/bin/env bash

OM_mkswap()
{
	dev=$1
	vol=$2

	devn=$dev

	if [ ! -b "$dev" ]
	then
		dev=${devn:0:-1}

	fi

	if [ "$vol" != "none" ]
	then
		echo Error: Invalid swap volume name: "$vol"
		return 1
	fi

	swapoff -a -v

	perl -pi.orig -e 's/^(.*none\s+swap\s+.*)$/#\1/;' /etc/fstab

	echo Partitioning $dev as linux-swap ...

	parted -s $dev mklabel msdos mkpart primary linux-swap 1M 100%

	if [ ! -b "$devn" ]
	then
		echo Error: Device not found: "$devn"
		return 1
	fi

	echo Creating swap on $devn ...

	mkswap -L swap -f $devn

	if [ "$?" -gt 0 ]
	then
		echo Error: mkswap failed to create swap on $devn
		return 1
	fi

	echo "Appending \"$devn none swap sw 0 0\"" to /etc/fstab

	echo "$devn none swap sw 0 0" >>/etc/fstab

	echo Mounting swap on $devn ...

	swapon -v $devn

	if [ "$?" -gt 0 ]
	then
		echo Error: swapon failed to mount $devn
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

		echo Partitioning $dev as ext2 ...

		parted -s $dev mklabel msdos mkpart primary ext2 1M 100%
	fi

	if [ ! -b "$devn" ]
	then
		echo Error: Device not found: "$devn"
		return 1
	fi

	echo Formatting $devn as $fmt ...

	case "$fmt" in
		jfs)
			MKFS_OPTS=-q
			;;
		*)
			MKFS_OPTS=
			;;
	esac

	mkfs.$fmt $MKFS_OPTS $devn

	if [ "$?" -gt 0 ]
	then
		mkfs.$fmt failed to format $devn
		return 1
	fi

	echo Appending "$devn $vol $fmt $opt $ex1 $ex2" to /etc/fstab ...

	echo "$devn $vol $fmt $opt $ex1 $ex2" >>/etc/fstab

	if [ ! -d "$vol" ]
	then
		echo Creating directory "$vol" ...
		mkdir -p "$vol"
	fi

	if [ ! -d "$vol" ]
	then
		return 1
	fi

	if [ "$vol" = "/tmp" ]
	then
		mode=1777
	else
		mode=0755
	fi

	voldir=`echo $vol | tr -d /`

	mnt=$OOOM_MOUNT/$voldir

	echo Creating directory "$mnt" ...

	mkdir -p --mode $mode $mnt

	if [ ! -d "$mnt" ]
	then
		return 1
	fi

	if [ "$vol" = "/tmp" ]
	then
		echo Skipping volume $vol
		return 0
	fi

	echo Mounting "$devn" on "$mnt" as "$fmt" using "$opt" ...

	mount -t $fmt -o $opt $devn $mnt

	EL=$?

	if [ "$EL" -gt "0" ]
	then
		if [ "$fmt" = "exfat" ]
		then
			$OOOM_INSTALL software-properties-common
			add-apt-repository -y ppa:relan/exfat
			$OOOM_INSTALL exfat-fuse

			echo Mounting "$devn" on "$mnt" as "$fmt" using "$opt" ...

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

	pushd $vol >/dev/null

	echo Copying "$vol" to "$mnt" ...

	find . -depth -print0 | cpio --null --sparse --make-directories --pass-through $mnt

	popd >/dev/null

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

	mnt=$OOOM_MOUNT/$voldir

	if [ ! -d "$mnt" ]
	then
		echo Error: Directory not found: "$mnt"
		return 1
	fi

	echo Renaming "$vol" to "$vol.orig" ...

	mv -f $vol $vol.orig

	if [ ! -d "$vol.orig" ]
	then
		echo Error: Directory not found: "$vol.orig"
		return 1
	fi

	if [ "$vol" = "/tmp" ]
	then
		mode=1777
	else
		mode=0755
	fi

	echo Creating directory "$vol" ...

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

	chmod $mode $vol
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

#set -o xtrace

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

OOOM_FSTABS=$OOOM_DIR/$OOOM_FSTAB

if [ ! -f "$OOOM_FSTABS" ]
then
	echo File not found: $OOOM_FSTABS
	exit 1
fi

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
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
done

# https://bugs.launchpad.net/ubuntu/+source/ntfs-3g/+bug/1148541

if [ ! -f /sbin/mkfs.ntfs ]
then
	if [ -f /sbin/mkntfs ]
	then
		ln -fs /sbin/mkntfs /sbin/mkfs.ntfs
	fi
fi

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
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
done

tac $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	OM_mvvol "$dev" "$vol"
done

for volmode in $OOOM_CHMODS
do
	vol=${volmode%%=*}
	mode=${volmode#*=}

	OM_chmod "$vol" "$mode"
done

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	if [ "$vol" != "$OOOM_GRUB_VOL" ]
	then
		continue
	fi

	echo NOTE: Grub installation not yet implemented, sorry.

#	OM_grubdev "dev" "$vol"
done

if [ -f "$OOOM_DIR/ooom-custom-boot-1-end.sh" ]
then
	"$OOOM_DIR/ooom-custom-boot-1-end.sh"
fi

# eof

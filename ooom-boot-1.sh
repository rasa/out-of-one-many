#!/usr/bin/env bash

OM_mkswap()
{
	dev=$1

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

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	echo "Appending \"$swap_partition none swap sw 0 0\"" to /etc/fstab

	echo "$swap_partition none swap sw 0 0" >>/etc/fstab

	swapon -v $swap_partition

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

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

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	if [ "$EL" -gt "0" ]
	then
		return $EL
	fi

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
		return 0
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	mode=0755

	mkdir -p --mode $mode $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	mount -t $fmt -o $opt $dev1 $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	if [ "$EL" -gt "0" ]
	then
		rmdir $mnt
		return $EL
	fi

	chmod $mode $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	pushd $vol

		find . -depth -print0 | cpio --null --sparse --make-directories --pass-through $mnt

		EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	popd

	return 0
}

OM_mountvol()
{
	dev=$1
	vol=$2

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		continue
	fi

	voldir=`echo $vol | tr -d /`

	mnt=/mnt/$voldir

	if [ ! -d "$mnt" ]
	then
		echo Error: Directory not found: $mnt
		return 1
	fi

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
		return 0
	fi

	umount $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"

	mount $vol

	EL=$? ; test "$EL" -gt 0 && echo "*** Command returned error $EL"
}

OM_grub_install()
{
	dev=$1
	vol=$2

	if [ ! -b "$dev" ]
	then
		echo Error: Device not found: "$dev"
		return 1
	fi

	if [ ! -d "$vol" ]
	then
		echo Error: Directory not found: $vol
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

		$OOOM_APT_GET install $package
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

	if [ "$fst" = "swap" ]
	then
		OM_mkfs "$dev" "$vol" "$fmt" "$opt" "$ex1" "$ex2"
		continue
	fi

	OM_mkfs "$dev" "$vol" "$fmt" "$opt" "$ex1" "$ex2"
done < $FSTAB_FILE

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	OM_mountvol "$dev" "$vol"
done < $FSTAB_FILE

while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	if [ "$vol" != "$OOOM_GRUB_VOL" ]
	then
		continue
	fi

	OM_grub_install "dev" "$vol"
done < $FSTAB_FILE

# eof

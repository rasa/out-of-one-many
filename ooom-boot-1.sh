#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# for debugging only:
set | sort

. "$SCRIPT_DIR/ooom-config.sh"

# for debugging only:
set | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

if [ ! -d "$LOG_DIR" ]
then
	mkdir -p "$LOG_DIR"
fi

pushd "$LOG_DIR"

echo '#############################################################'
echo === 1100-apt-install-boot1-packages
echo '#############################################################'

# for debugging only:
dpkg -l >dpkg--list-boot1-0.log

for package in $BOOT1_PACKAGES
do
	echo === Executing: $APT_GET install $package

	$APT_GET install $package

	echo === \$?=$?
done

# for debugging only:
dpkg -l >dpkg-list-boot1-1.log

echo '#############################################################'
echo === 1200-prepare-swap
echo '#############################################################'

cat /etc/fstab   >fstab1.out
cat /proc/mounts >mount1.out
parted -l        >parted1.out

if [ -b "$SWAP_DEV" ]
then
	echo === Executing: swapon -s

	swapon -s > swapon1.out

	echo === \$?=$?

	echo === Executing: swapoff -a -v

	swapoff -a -v

	echo === \$?=$?

	swapon -s >swapon2.out

	perl -pi.orig -e 's/^(.*none\s+swap\s+sw.*)$/#\1/;' /etc/fstab

	cat /etc/fstab >fstab1b.out

	echo === parted -s $SWAP_DEV mklabel msdos mkpart primary linux-swap 1M 100%

	parted -s $SWAP_DEV mklabel msdos mkpart primary linux-swap 1M 100%

	swap_partition=${SWAP_DEV}1

	if [ ! -b "$swap_partition" ]
	then
		echo === Device not found: "$swap_partition"
	else
		echo === Executing: mkswap -L swap -f $swap_partition

		mkswap -L swap -f $swap_partition

		echo === \$?=$?

		echo "$swap_partition none swap sw 0 0" >>/etc/fstab

		echo === Executing: swapon -v $swap_partition

		swapon -v $swap_partition

		echo === \$?=$?

		swapon -a -v >swapon3.out

		swapon -s >swapon4.out
	fi
fi

cat /etc/fstab   >fstab2.out
cat /proc/mounts >mount2.out
parted -l        >parted2.out

echo '#############################################################'
echo === 1210-format-volumes
echo '#############################################################'

for entry in $DISK_MAP
do
	dev=${entry%%,*}
	volfmtopt=${entry#*,}
	vol=${volfmtopt%%,*}

	echo === dev=$dev
	echo === volfmtopt=$volfmtopt
	echo === vol=$vol

	fmtopt=${volfmtopt#*,}

	echo === fmtopt=$fmtopt

	if [ "$fmtopt" = "$vol" ]
	then
		fmtopt=
	fi

	fmt=${fmtopt%%,*}
	opt=${fmtopt#*,}

	echo === fmt=$fmt
	echo === opt=$opt

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

	echo === fmt=$fmt
	echo === opt=$opt
	echo === dev1=$dev1

	if [ ! -b "$dev" ]
	then
		echo === Device not found: "$dev"
		continue
	fi

#	if [ "$vol" = "/boot" ]
#	then
#		fmt=ext2
#		opt=ro
#	fi

	#label=`echo $vol | tr -d /`
	label=$vol

	echo === label=$label

	echo === Executing: parted -s $dev mklabel msdos mkpart primary ext2 1M 100%

	parted -s $dev mklabel msdos mkpart primary ext2 1M 100%

	echo === \$?=$?

	if [ ! -b "$dev1" ]
	then
		echo === $dev1 not found
		continue
	fi

	echo === Executing: mkfs.$fmt $dev1

	mkfs.$fmt $dev1

	if [ "$?" -eq "0" ]
	then
		echo === Appending "$dev1 $vol $fmt $opt 0 2" to /etc/fstab

		echo "$dev1 $vol $fmt $opt 0 2" >>/etc/fstab

		if [ ! -d "$vol" ]
		then
			echo === Executing: mkdir -p "$vol"

			mkdir -p "$vol"

			echo === \$?=$?
		fi

		if [ "$vol" = "/tmp" ]
		then
			echo Skipping volume $vol
			continue
		fi

		voldir=`echo $vol | tr -d /`

		echo === voldir=$voldir

		mnt=/mnt/$voldir

		echo === mnt=$mnt

		mode=0755

		echo === Executing: mkdir -p --mode $mode $mnt

		mkdir -p --mode $mode $mnt

		echo === \$?=$?

		echo === Executing: mount -t $fmt -o $opt $dev1 $mnt

		mount -t $fmt -o $opt $dev1 $mnt

		if [ "$?" -gt "0" ]
		then
			rmdir $mnt
		else
			echo === Executing: chmod $mode $mnt

			chmod $mode $mnt

			echo === \$?=$?

			echo === Executing: ls -ld $mnt

			ls -ld $mnt

			pushd $vol

				echo === Executing: cpio --null --sparse --make-directories --pass-through --verbose $mnt

				find . -depth -print0 | cpio --null --sparse --make-directories --pass-through --verbose $mnt

				echo === \$?=$?

			popd

			echo === Executing: ls -ld $mnt

			ls -ld $mnt
		fi
	fi
done

cat /etc/fstab   >fstab3.out
cat /proc/mounts >mount3.out
parted -l        >parted3.out

echo '#############################################################'
echo === 1220-copy-volume-data
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

	voldir=`echo $vol | tr -d /`

	echo === voldir=$voldir

	mnt=/mnt/$voldir

	echo === mnt=$mnt

	if [ -d "$mnt" ]
	then
		if [ "$vol" = "/tmp" ]
		then
			mode=1777
		else
			mode=0755
		fi

		echo === mode=$mode

		echo === mv -f $vol $vol.orig

		mv -f $vol $vol.orig

		echo === Executing: mkdir -p --mode $mode $vol

		mkdir -p --mode $mode $vol

		echo === \$?=$?

		echo === Executing: ls -ld $vol

		ls -ld $vol

		echo === Executing: chmod $mode $vol

		chmod $mode $vol

		echo === \$?=$?

		echo === Executing: ls -ld $vol

		ls -ld $vol

		if [ "$vol" = "/tmp" ]
		then
			continue
		fi

		echo === Executing: umount $mnt

		umount $mnt

		echo === \$?=$?

		echo === Executing: mount $vol

		mount $vol

		echo === \$?=$?
	fi
done

cat /etc/fstab   >fstab4.out
cat /proc/mounts >mount4.out
parted -l        >parted4.out

echo '#############################################################'
echo === 1230-prepare-boot-volume
echo '#############################################################'

if [ -f /boot/grub/grub.cfg ]
then
	cp -p /boot/grub/grub.cfg $LOG_DIR/grub.cfg
	cp -p /boot/grub/menu.lst $LOG_DIR/menu.lst
fi

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

	if [ ! -b "$MBR_DEV" ]
	then
		echo === Device not found: "$MBR_DEV"
		continue
	fi

	if [ "$vol" != "$GRUB_VOL" ]
	then
		continue
	fi

	if [ ! -d "$vol" ]
	then
		echo === Directory not found: $vol
		continue
	fi

	echo === Executing: grub-install --boot-directory=$GRUB_VOL $MBR_DEV

	grub-install --boot-directory=$GRUB_VOL $MBR_DEV

	echo === \$?=$?

	echo === Executing: update-grub

	update-grub

	echo === \$?=$?

	if [ -f /boot/grub/grub.cfg ]
	then
		cp -p /boot/grub/grub.cfg $LOG_DIR/grub-2.cfg
		cp -p /boot/grub/menu.lst $LOG_DIR/menu-2.lst
	fi

	cat /etc/fstab   >fstab5.out
	cat /proc/mounts >mount5.out
	parted -l        >parted5.out

done

# eof

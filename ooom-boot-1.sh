#!/usr/bin/env bash

OM_install()
{
	fmt=$1

	if [ -z "$fmt" ]
	then
		return 0
	fi

	for entry in $OOOM_PACKAGE_MAP
	do
		fs=${entry%%,*}
		package=${entry#*,}

		if [ "$fmt" != "$fs" ]
		then
			continue
		fi

		if [ "$fmt" = "exfat" ]
		then
			echo Installing package software-properties-common for $fmt ...

			$OOOM_INSTALL software-properties-common

			if [ -f /etc/init.d/unattended-upgrades ]
			then
				echo Running /etc/init.d/unattended-upgrades stop ...
				/etc/init.d/unattended-upgrades stop
			fi

			echo Running service unattended-upgrades stop ...

			service unattended-upgrades stop

			echo Running add-apt-repository -y ppa:relan/exfat ...

			add-apt-repository -y ppa:relan/exfat

			echo Installing package exfat-fuse for $fmt ...

			$OOOM_INSTALL exfat-fuse
		fi

		echo Installing package $package for $fmt ...

		$OOOM_INSTALL $package
	done

	if [ -f /etc/init.d/unattended-upgrades ]
	then
		echo Running /etc/init.d/unattended-upgrades stop ...
		/etc/init.d/unattended-upgrades stop
	fi

	echo Running service unattended-upgrades stop ...

	service unattended-upgrades stop
}

OM_mkswap()
{
	devn=$1
	vol=$2
	uuid=$7

	dev=${devn:0:-1}
	partition=${devn#${devn%?}}

	if [ ! -b "$dev" ]
	then
		echo "*** Error: Device not found: $dev"
		return 1
	fi

	if [ -z "$vol" ]
	then
		echo "*** Error: Empty volume for device $devn"
		return 1
	fi

	if [ "$vol" != "none" ]
	then
		echo "*** Error: Expected swap volume name 'none', found '$vol'"
		return 1
	fi

	swapoff -a -v

	if [ -b "$devn" ]
	then
		parted -s $dev rm $partition
	fi

	echo Partitioning $dev as linux-swap ...

	parted -s $dev mklabel msdos mkpart primary linux-swap 1M 100%

	if [ ! -b "$devn" ]
	then
		echo "*** Error: Device not found: $devn"
		return 1
	fi

	echo Creating swap on $devn ...

	MKSWAP_OPTS=

	if [ "$uuid" ]
	then
		MKSWAP_OPTS="$MKSWAP_OPTS -U $uuid"
	fi

	mkswap -L swap $MKSWAP_OPTS -f $devn

	if [ "$?" -gt 0 ]
	then
		echo "*** Error: mkswap failed to create swap on $devn"
		return 1
	fi

	echo Commenting out $vol in /etc/fstab ...

	perl -pi.swap.ooomed -e 's/^\s*(\S+\s+none\s+swap\s+.*)$/#\1/;' /etc/fstab

	echo "Appending \"$devn none swap sw 0 0\"" to /etc/fstab

	echo -e "$devn\tnone\tswap\tsw\t0\t0" >>/etc/fstab

	echo Mounting swap on $devn ...

	swapon -v $devn

	if [ "$?" -gt 0 ]
	then
		echo "*** Error: swapon failed to mount $devn"
		return 1
	fi

	swapon -a -v

	swapon -s
}

OM_mkfs()
{
	devn=$1
	vol=$2
	fmt=$3
	opt=$4
	ex1=$5
	ex2=$6
	uuid=$7

	dev=${devn:0:-1}
	partition=${devn#${devn%?}}

	if [ ! -b "$dev" ]
	then
		echo "*** Error: Device not found: $dev"
		return 1
	fi

	if [ -z "$vol" ]
	then
		echo "*** Error: Empty volume for device $devn"
		return 1
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

	if [ -b "$devn" ]
	then
		echo Removing partition $partition on $dev ...

		parted -s $dev rm $partition
	fi

	if [ -b "$devn" ]
	then
		echo "*** Error: Unable to remove device: $devn"
		return 1
	fi

	if [ "$fmt" = "swap" ]
	then
		OM_mkswap "$devn" "$vol" "$fmt" "$opt" "$ex1" "$ex2" "$uuid"
		return
	fi

	echo Partitioning $dev ...

	parted -s $dev mklabel msdos mkpart primary ext2 1M 100%

	if [ ! -b "$devn" ]
	then
		echo "*** Error: Device not found: $devn"
		return 1
	fi

	echo Formatting $devn as $fmt ...

	MKFS_OPTS=

	case "$fmt" in
		ext2|ext3|ext4)
			if [ "$uuid" ]
			then
				MKFS_OPTS="-U $uuid"
			fi
			;;
		exfat)
			# 16 chars max?
			#MKFS_OPTS="-n $label"
			;;
		jfs)
			MKFS_OPTS=-q
			;;
		ntfs)
			# 16 chars max?
			#MKFS_OPTS="-L $label"
			MKFS_OPTS=-f
			;;
		vfat)
			# 16 chars max?
			#MKFS_OPTS="-n $label"
			;;
		xfs)
			# 12 chars max
			#MKFS_OPTS="-L $label"
			;;
	esac

	mkfs.$fmt $MKFS_OPTS $devn

	if [ "$?" -gt 0 ]
	then
		mkfs.$fmt failed to format $devn
		return 1
	fi

	voldir=`echo $vol | tr -d /`

	mnt=$OOOM_MOUNT/$voldir

	echo Creating directory $mnt ...

	mkdir -pv $mnt

	if [ ! -d "$mnt" ]
	then
		return 1
	fi

	if [ "$opt" = "ro" ]
	then
		opt=defaults
	fi

	echo Mounting $devn on $mnt as $fmt using $opt ...

	mount -v -t $fmt -o $opt $devn $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	if [ "$EL" -gt "0" ]
	then
		rmdir $mnt
		return 1
	fi

	if [ ! -d "$vol" ]
	then
		echo Skipping copying $vol to $mnt as $vol does not exist
	else
		pushd $vol >/dev/null

			echo Copying $vol to $mnt ...

			find . -depth -xdev -print0 | cpio --null --sparse --make-directories --pass-through $mnt

			if [ "$?" -gt 0 ]
			then
				echo Unmounting $mnt ...
				umount -v $mnt
				return 1
			fi

		popd >/dev/null

		chmod -v --reference=$vol $mnt

		EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

		if which rsync >/dev/null 2>/dev/null
		then
			rsync -v -ptgo -A -X -d --no-recursive --exclude=* $vol $mnt

			EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"
		fi

	fi

	if egrep -v '^\s*#' /etc/fstab.pre-ooomed | tr -s "\t" " " | cut -d' ' -f 2 | egrep -q "^$vol$"
	then
		echo Commenting out $vol in /etc/fstab ...

		perl -pi.$voldir.ooomed -e "s|^\s*(\S+\s+$vol\s+.*)$|#\1|;" /etc/fstab
	fi

	echo "Appending '$devn $vol $fmt $opt $ex1 $ex2' to /etc/fstab ..."

	echo -e "$devn\t$vol\t$fmt\t$opt\t$ex1\t$ex2" >>/etc/fstab

	return 0
}

OM_mkvol()
{
	devn=$1
	vol=$2

	if [ ! -b "$devn" ]
	then
		echo "*** Error: Device not found: $devn"
		return 1
	fi

	if [ -z "$vol" ]
	then
		echo "*** Error: Empty volume for device $devn"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		echo Skipping volume: $vol
		return 0
	fi

	if egrep -v '^\s*#' /etc/fstab.pre-ooomed | tr -s "\t" " " | cut -d' ' -f 2 | egrep -q "^$vol$"
	then
		echo Skipping renaming $vol as it is in /etc/fstab
		return 0
	fi

	voldir=`echo $vol | tr -d /`

	mnt=$OOOM_MOUNT/$voldir

	if [ ! -d "$mnt" ]
	then
		echo "*** Error: Volume not found: $mnt"
		return 1
	fi

	if [ -d "$vol" ]
	then
		echo Renaming volume $vol to $vol.ooomed ...

		mv -fv $vol $vol.ooomed

		if [ ! -d "$vol.ooomed" ]
		then
			echo "*** Error: Volume not found: $vol.ooomed"
			return 1
		fi
	fi

	echo Creating volume $vol ...

	mkdir -v $vol

	if [ ! -d "$vol" ]
	then
		echo "*** Error: Unable to create volume: $vol"
		return 1
	fi
}

OM_rmmnt()
{
	devn=$1
	vol=$2

	if [ "$vol" = "none" ]
	then
		echo Skipping volume $vol
		return 0
	fi

	voldir=`echo $vol | tr -d /`

	mnt=$OOOM_MOUNT/$voldir

	if [ ! -d "$mnt" ]
	then
		echo Skipping unmounting $mnt as it does not exist
		return 0
	fi

	echo Unmounting $mnt ...

	umount -v $mnt

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	echo Removing $mnt ...

	rmdir -v "$mnt"

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"
}

OM_setboot()
{
	devn=$1
	vol=$2

	dev=${devn:0:-1}
	partition=${devn#${devn%?}}

	if [ ! -b "$dev" ]
	then
		echo "*** Error: Device not found: $dev"
		return 1
	fi

	if [ -z "$vol" ]
	then
		echo "*** Error: Empty volume for device $devn"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		echo Skipping volume: $vol
		return 0
	fi

	if ! egrep -v '^\s*#' /etc/fstab.pre-ooomed | tr -s "\t" " " | cut -d' ' -f 2 | egrep -q "^$vol$"
	then
		echo "*** Error: Boot volume $vol was not found in /etc/fstab, so ooom cannot set $dev bootable"
		return 1
	fi

	echo Turning off boot flags on the following partitions:

	parted -s -l -m | perl -n -e 'if (m|^(/dev/\w+)|) {$d=$1} if (m|^(\d+):.*:boot;|) {print "parted -s $d set $1 boot off\n";};'

	parted -s -l -m | perl -n -e 'if (m|^(/dev/\w+)|) {$d=$1} if (m|^(\d+):.*:boot;|) {`parted -s $d set $1 boot off`;};'

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	echo Turning on boot flag for partition $partition on $dev ...

	parted -s $dev set $partition boot on

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	return $EL
}

OM_installgrub()
{
	devn=$1
	vol=$2

	dev=${devn:0:-1}

	if [ ! -b "$dev" ]
	then
		echo "*** Error: Device not found: $dev"
		return 1
	fi

	if [ -z "$vol" ]
	then
		echo "*** Error: Empty volume for device $devn"
		return 1
	fi

	if [ "$vol" = "none" ]
	then
		echo Skipping volume: $vol
		return 0
	fi

	if [ ! -d "$vol" ]
	then
		echo "*** Error: Volume not found: $vol"
		return 1
	fi

	echo Unmounting $vol ...

	umount -v $vol

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	echo Mounting $vol ...

	mount -v $vol

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	grub-install --boot-directory=$vol "$dev"

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	update-grub

	EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"

	return $EL
}

#set -o xtrace

echo $0 started at `date`

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

cd "$OOOM_DIR"

# for debugging only:
env | sort

. $OOOM_DIR/ooom-config.sh

# for debugging only:
env | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

cp -p /etc/fstab /etc/fstab.pre-ooomed

if [ -f "$OOOM_DIR/ooom-custom-boot-1-start.sh" ]
then
	echo Running $OOOM_DIR/ooom-custom-boot-1-start.sh ...

	$OOOM_DIR/ooom-custom-boot-1-start.sh

	echo $OOOM_DIR/ooom-custom-boot-1-start.sh returned $?
fi

OOOM_FSTABS=$OOOM_DIR/$OOOM_FSTAB

if [ ! -f "$OOOM_FSTABS" ]
then
	echo File not found: $OOOM_FSTABS
	exit 1
fi

if [ -f /etc/init.d/unattended-upgrades ]
then
	service unattended-upgrades stop
fi

ls -l /                 >$OOOM_LOG_DIR/ls-1.log
cat /proc/mounts | sort >$OOOM_LOG_DIR/mounts-1.log
parted -s -l 2>&1       >$OOOM_LOG_DIR/parted-1.log
swapon -s 2>&1          >$OOOM_LOG_DIR/swapon-1.log

echo === Step 1: OM_install

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	fmt=${var[2]}

	if echo "$dev" | egrep -q "^\s*#"
	then
		continue
	fi

	OM_install "$fmt"
done

echo === Step 2: post OM_install fix

# see https://bugs.launchpad.net/ubuntu/+source/ntfs-3g/+bug/1148541

if [ ! -f /sbin/mkfs.ntfs ]
then
	if [ -f /sbin/mkntfs ]
	then
		ln -fs /sbin/mkntfs /sbin/mkfs.ntfs
	fi
fi

echo === Step 3: OM_mkfs

disk_id=1

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}
	fmt=${var[2]}
	opt=${var[3]}
	ex1=${var[4]}
	ex2=${var[5]}

	if echo "$dev" | egrep -q "^\s*#"
	then
		continue
	fi

	if [ "$OOOM_UUID" ]
	then
		hex_disk_id=$(printf "%02x" $disk_id)
		uuid=${OOOM_UUID:0:-2}$hex_disk_id
		disk_id=$(($disk_id + 1))
	else
		uuid=
	fi

	OM_mkfs "$dev" "$vol" "$fmt" "$opt" "$ex1" "$ex2" "$uuid"
done

echo === Step 4: OM_mkvol

tac $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	if echo "$dev" | egrep -q "^\s*#"
	then
		continue
	fi

	if [ "$vol" = "$OOOM_BOOT_VOL" ]
	then
		if ! egrep -v '^\s*#' /etc/fstab.pre-ooomed | tr -s "\t" " " | cut -d' ' -f 2 | egrep -q "^$vol$"
		then
			echo Warning: Boot volume "$vol" was not found in /etc/fstab, so ooom cannot create it
			continue
		fi
	fi

	OM_mkvol "$dev" "$vol"
done

echo === Step 5: OM_rmmnt

cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
do
	dev=${var[0]}
	vol=${var[1]}

	if echo "$dev" | egrep -q "^\s*#"
	then
		continue
	fi

	OM_rmmnt "$dev" "$vol"
done

if [ "$OOOM_BOOT_VOL" ]
then
	echo === Step 6: OM_setboot

	cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
	do
		dev=${var[0]}
		vol=${var[1]}

		if echo "$dev" | egrep -q "^\s*#"
		then
			continue
		fi

		if [ "$vol" = "$OOOM_BOOT_VOL" ]
		then
			OM_setboot "$dev" "$vol"
			break
		fi
	done
fi

if [ "$OOOM_GRUB_VOL" ]
then
	echo === Step 7: OM_installgrub

	cat $OOOM_FSTABS | while IFS=$' \t' read -r -a var
	do
		dev=${var[0]}
		vol=${var[1]}

		if echo "$dev" | egrep -q "^\s*#"
		then
			continue
		fi

		if [ "$vol" = "$OOOM_GRUB_VOL" ]
		then
			OM_installgrub "dev" "$vol"
			break
		fi
	done
fi

if [ -f "$OOOM_DIR/ooom-custom-boot-1-end.sh" ]
then
	echo Running $OOOM_DIR/ooom-custom-boot-1-end.sh ...

	$OOOM_DIR/ooom-custom-boot-1-end.sh

	echo $OOOM_DIR/ooom-custom-boot-1-end.sh returned $?
fi

ls -l /                 >$OOOM_LOG_DIR/ls-1b.log
cat /proc/mounts | sort >$OOOM_LOG_DIR/mounts-1b.log
parted -s -l 2>&1       >$OOOM_LOG_DIR/parted-1b.log
swapon -s 2>&1          >$OOOM_LOG_DIR/swapon-1b.log

# rm -f /etc/fstab.*ooomed

echo $0 finished at `date`

# eof

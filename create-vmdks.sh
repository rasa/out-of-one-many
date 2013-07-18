#!/usr/bin/env bash

#set -x
set -e

if [ -z "$disks" ]
then
	disks=25
fi

VDISKMANAGER_OPTIONS="-s 64GB -t 0"

VMWARE_VDISKMANAGER=$(which vmware-vdiskmanager 2>/dev/null || true)

if [ -z "$VMWARE_VDISKMANAGER" ]
then
	if [ -d "/cygdrive/c/Program Files (x86)/VMware/VMware Workstation" ]
	then
		PATH="$PATH:/cygdrive/c/Program Files (x86)/VMware/VMware Workstation"
	fi
fi

vmx=`ls -1 *.vmx 2>/dev/null | head -n 1`

if [ ! -f "$vmx" ]
then
	echo $0: No .vmx file found in `pwd` >&2
	exit 1
fi

vmdk=`ls -1 *.vmdk 2>/dev/null | head -n 1`

if [ ! -f "$vmdk" ]
then
	echo $0: No .vmdk file found in `pwd` >&2
	exit 2
fi

bvmdk=`basename $vmdk .vmdk`

mkdir -p originals

cp -p $vmx $vmx~

bus=0
dev=1

prefix=

for i in `seq 1 $disks`
do
	remainder=$(($i % 26))

	if [ "$remainder" -eq "0" ]
	then
		if [ "$prefix" = "a" ]
		then
			prefix=b
		else
			prefix=a
		fi
	fi
	# a=96 ascii
	o=$((97 + $remainder))
	c=$(printf \\$(printf '%03o' $o))
	vmdk=$bvmdk-$prefix$c.vmdk

	if egrep -q "scsi$bus:$dev\." $vmx
	then
		echo $0: $vmx already references SCSI disk $bus:$dev >&2
		exit 3
	fi

	echo $VMWARE_VDISKMANAGER -c $VDISKMANAGER_OPTIONS $* $vmdk
	$VMWARE_VDISKMANAGER -c $VDISKMANAGER_OPTIONS $* $vmdk

	echo -e "scsi$bus:$dev.present = \"TRUE\"" >>$vmx
	echo -e "scsi$bus:$dev.fileName = \"$vmdk\"" >>$vmx

	dev=$(($dev + 1))

	if [ "$dev" -eq "7" ]
	then
		dev=$(($dev + 1))
	fi

	if [ "$dev" -gt "15" ]
	then
		bus=$(($bus + 1))
		dev=0
		echo -e "scsi$bus.present = \"TRUE\"" >>$vmx
		echo -e "scsi$bus.virtualDev = \"lsilogic\"" >>$vmx
	fi
done

cp -pr *.vmdk originals

#!/usr/bin/env bash

# shrink VMWare virtual disks (.vmdks)

#set -x
set -e

VDISKMANAGER_OPTIONS="-s 64GB -t 0"

VMWARE_VDISKMANAGER=$(which vmware-vdiskmanager 2>/dev/null || true)

if [[ -z "$VMWARE_VDISKMANAGER" ]]; then
  if [[ -d "/cygdrive/c/Program Files (x86)/VMware/VMware Workstation" ]]; then
    PATH="$PATH:/cygdrive/c/Program Files (x86)/VMware/VMware Workstation"
  fi
fi

VMDKS=$(ls -1 *.vmdk 2>/dev/null | wc -l)

if [[ "$VMDKS" -eq 0 ]]; then
  echo No .vmdk files found in $(pwd) >&2
  exit 1
fi

OLD=$(du -cm *.vmdk | sort -nr | head -n 1 | cut -f 1)

for vmdk in *.vmdk
do
  echo $vmdk:
  #vmware-vdiskmanager -R $vmdk
  vmware-vdiskmanager -d $vmdk
  vmware-vdiskmanager -k $vmdk
  chmod a+r,u+w $vmdk
done

NEW=$(du -cm *.vmdk | sort -nr | head -n 1 | cut -f 1)

SAVINGS=$(( ($OLD - $NEW) * 100 / $OLD ))

printf "Shrunk %d vmdks from %d to %d megabytes (%d%% savings)\n" $VMDKS $OLD $NEW $SAVINGS

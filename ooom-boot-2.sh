#!/usr/bin/env bash

# create and partition disks per ooom.fstab file - second boot

# TODO(ross) add function comments
ooom::mkvol() {
  devn="$1"
  vol="$2"

  if [[ ! -b "${devn}" ]]; then
    echo "*** Error: Device not found: ${devn}"
    return 1
  fi

  if [[ -z "${vol}" ]]; then
    echo "*** Error: Invalid volume: ${vol}"
    return 1
  fi

  if [[ "${vol}" = "none" ]]; then
    echo Skipping volume: ${vol}
    return 0
  fi

  if [[ -d "${vol}" ]]; then
    echo Skipping volume ${vol} as it already exists
    return 0
  fi

  if [[ "${vol}" = "/tmp" ]]; then
    mode=1777
  else
    mode=0755
  fi

  echo Creating volume ${vol} with mode ${mode} ...

  mkdir -pv --mode "${mode}" "${vol}"

  if [[ ! -d "${vol}" ]]; then
    echo "*** Error: Volume not found: ${vol}"
    return 1
  fi

  echo Mounting ${vol} on ${devn} ...

  mount -v "${vol}"

  EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"
}

# TODO(ross) add function comments
ooom::rmbackup() {
  devn="$1"
  vol="$2"

  if [[ "${vol}" = "none" ]]; then
    return 0
  fi

  if [[ ! -b "${devn}" ]]; then
    echo "*** Error: Device not found: ${devn}"
    return 1
  fi

  if [[ ! -d "${vol}" ]]; then
    echo "*** Error: Volume not found: ${vol}"
    return 1
  fi

  if [[ ! -d "${vol}.ooomed" ]]; then
    if ! egrep -v '^\s*#' /etc/fstab.pre-ooomed | tr -s "\t" " " | cut -d' ' -f 2 | egrep -q "^${vol}$"; then
      echo Warning: Volume not found: ${vol}.ooomed
      return 1
    fi
  fi

  echo Removing "${vol}.ooomed" ...

  rm -fr "${vol}.ooomed"

  EL=$? ; test "$EL" -gt 0 && echo "*** Error: Command returned error $EL"
}

#set -o xtrace

echo $0 started at $(date)

OOOM_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${OOOM_DIR}"

# for debugging only:
#env | sort

. "${OOOM_DIR}/ooom-config.sh"

# for debugging only:
#env | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

ls -l /                 >${OOOM_LOG_DIR}/ls-2.log
cat /proc/mounts | sort >${OOOM_LOG_DIR}/mounts-2.log
parted -s -l 2>&1       >${OOOM_LOG_DIR}/parted-2.log
swapon -s 2>&1          >${OOOM_LOG_DIR}/swapon-2.log

if [[ -f "${OOOM_DIR}/ooom-custom-boot-2-start.sh" ]]; then
  echo Running ${OOOM_DIR}/ooom-custom-boot-2-start.sh ...

  ${OOOM_DIR}/ooom-custom-boot-2-start.sh

  echo ${OOOM_DIR}/ooom-custom-boot-2-start.sh returned $?
fi

OOOM_FSTABS="${OOOM_DIR}/${OOOM_FSTAB}"

if [[ ! -f "${OOOM_FSTABS}" ]]; then
  echo File not found: ${OOOM_FSTABS}
  exit 1
fi

echo === Step 1: ooom::mkvol

cat "${OOOM_FSTABS}" | while IFS=$' \t' read -r -a var; do
  dev="${var[[0]]}"
  vol="${var[[1]]}"

  if echo "${dev}" | egrep -q "^\s*#"; then
    continue
  fi

  if [[ "${vol}" = "$OOOM_BOOT_VOL" ]]; then
    continue
  fi

  ooom::mkvol "${dev}" "${vol}"
done

if [[ "$OOOM_REMOVE_BACKUPS" ]]; then
  echo === Step 2: ooom::rmbackup

  tac "${OOOM_FSTABS}" | while IFS=$' \t' read -r -a var; do
    dev="${var[[0]]}"
    vol="${var[[1]]}"

    if echo "${dev}" | egrep -q "^\s*#"; then
      continue
    fi

    ooom::rmbackup "${dev}" "${vol}"
  done
fi

echo === Step 3: zero volumes

for vol in ${OOOM_SHRINK_DISKS}; do
  if [[ ! -d "${vol}" ]]; then
    echo "*** Error: Volume not found: ${vol}"
    continue
  fi

  if [[ "${vol}" != "/" ]]; then
    vol="${vol}/"
  fi

  zero="${vol}ZERO_FREE_SPACE"

  echo Zeroing free space on ${vol} ...

  dd if=/dev/zero of=${zero} bs=1M

  rm -f "${zero}"
done

if [[ -d "${OOOM_MOUNT}" ]]; then
  rmdir "${OOOM_MOUNT}"
fi

OOOM_RC_LOCAL=/etc/rc.local.ooomed

if [[ -f "${OOOM_RC_LOCAL}" ]]; then
  cp -p "${OOOM_RC_LOCAL}" /etc/rc.local
else
  rm -f /etc/rc.local
fi

if [[ -f "${OOOM_DIR}/ooom-custom-boot-1-end.sh" ]]; then
  echo Running ${OOOM_DIR}/ooom-custom-boot-1-end.sh ...

  ${OOOM_DIR}/ooom-custom-boot-1-end.sh

  echo ${OOOM_DIR}/ooom-custom-boot-1-end.sh returned $?
fi

ls -l / >${OOOM_LOG_DIR}/ls-2b.log

echo $0 finished at $(date)

# eof

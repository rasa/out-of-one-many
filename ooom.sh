#!/usr/bin/env bash

OOOM_VERSION="0.1.0"

echo $OOOM_VERSION >/etc/.ooom_version

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

# for debugging only:
#env | sort >/ooom.log

. "$OOOM_DIR/ooom-config.sh"

# for debugging only:
#env | sort | grep _ | egrep -v '^(BASH|UPSTART)_' >/ooom2.log

if [ ! -d "$OOOM_LOG_DIR" ]
then
	mkdir -p "$OOOM_LOG_DIR"
fi

LOG=$OOOM_LOG_DIR/ooom.log

if [ -f "$OOOM_DIR/ooom-custom-start.sh" ]
then
	echo `date +'%F %T'` Executing: "$OOOM_DIR/ooom-custom-start.sh" | tee -a $LOG

	"$OOOM_DIR/ooom-custom-start.sh"
fi

for i in 1 2
do
	file="$OOOM_DIR/ooom-boot-$i.sh"

	if [ ! -f "$file" ]
	then
		continue
	fi

	echo `date +'%F %T'` Executing: bash "$file" | tee -a $LOG

	LOGN=$OOOM_LOG_DIR/ooom-boot-$i.log

	bash "$file" 2>&1 | tee -a $LOGN

	echo `date +'%F %T'` $file returned $? | tee -a $LOG

	mv -f "$file" "$file.disabled.sh"

	j=$(($i + 1))

	nextfile="$OOOM_DIR/ooom-boot-$j.sh"

	if [ -f "$nextfile" ]
	then
		echo `date +'%F %T'` Executing: shutdown -r now | tee -a $LOG

		shutdown -r now
		exit 0
	fi

	break
done

perl -pi.final.ooomed -e 's|\s*#?\s*/etc/ooom\.sh.*$||' /etc/rc.local

if [ -f "$OOOM_DIR/ooom-custom-end.sh" ]
then
	echo `date +'%F %T'` Executing: "$OOOM_DIR/ooom-custom-end.sh" | tee -a $LOG

	"$OOOM_DIR/ooom-custom-end.sh"
	exit 0
fi

if [ "$OOOM_EXIT_COMMAND" ]
then
	echo `date +'%F %T'` Executing: $OOOM_EXIT_COMMAND | tee -a $LOG

	$OOOM_EXIT_COMMAND
fi

# eof

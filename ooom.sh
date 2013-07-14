#!/usr/bin/env bash

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

# for debugging only:
#set | sort

. "$OOOM_DIR/ooom-config.sh"

# for debugging only:
#set | sort | grep _ | egrep -v '^(BASH|UPSTART)_'

if [ ! -d "$OOOM_LOG_DIR" ]
then
	mkdir -p "$OOOM_LOG_DIR"
fi

for i in `seq 1 1 10`
do
	file="$OOOM_DIR/ooom-boot-$i.sh"

	if [ ! -f "$file" ]
	then
		continue
	fi

	LOG=$OOOM_LOG_DIR/ooom.log

	echo Executing: bash -x "$file" at `date` | tee -a $LOG

	LOGN=$OOOM_LOG_DIR/ooom-boot-$i.log

	bash -x "$file" 2>&1 | tee -a $LOGN

	echo $file returned $? at `date` | tee -a $LOG

	mv "$file" "$file.done"

	j=$(($i + 1))

	nextfile="$OOOM_DIR/ooom-boot-$j.sh"

	if [ -f "$nextfile" ]
	then
		echo Executing: shutdown -r now | tee -a $LOG

		shutdown -r now
		exit
	fi

	if [ "$OOOM_FINAL_COMMAND" ]
	then
		echo Executing: $OOOM_FINAL_COMMAND | tee -a $LOG

		$OOOM_FINAL_COMMAND
	fi

done

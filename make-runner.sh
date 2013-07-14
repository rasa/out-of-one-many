#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

rm -fr ooom ooom.run

mkdir -p ooom

git archive master | tar -x -C ooom

MAKESELF=`which makeself.sh 2>/dev/null || true`

if [ -z "$MAKESELF" ]
then
	git clone https://github.com/megastep/makeself.git
	export PATH=`pwd`/makeself:$PATH
	MAKESELF=`which makeself.sh 2>/dev/null || true`
fi

$MAKESELF --notemp ooom ooom.run "Out of one, many: Move and mount directories to different disks"

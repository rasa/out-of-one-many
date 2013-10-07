#!/usr/bin/env bash

OOOM_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$OOOM_DIR" >/dev/null

TMP_DIR=out-of-one-many

rm -fr $TMP_DIR *.run

mkdir -p $TMP_DIR

git archive master | tar -x -C $TMP_DIR

rm -f $TMP_DIR/*.run

MAKESELF=`which makeself.sh 2>/dev/null || true`

if [ -z "$MAKESELF" ]
then
	git clone https://github.com/megastep/makeself.git
	export PATH=`pwd`/makeself:$PATH
	MAKESELF=`which makeself.sh 2>/dev/null || true`
fi

$MAKESELF --notemp $TMP_DIR ooom.run "Out of one, many: Move directories to different partitions"

$MAKESELF --notemp $TMP_DIR autorun.run "Out of one, many: Move directories to different partitions" ./autorun.sh

rm -fr $TMP_DIR

popd >/dev/null

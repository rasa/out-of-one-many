#!/usr/bin/env bash

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

pushd "$OOOM_DIR" >/dev/null

rm -fr out-of-one-many ooom.run

mkdir -p out-of-one-many

git archive master | tar -x -C out-of-one-many

MAKESELF=`which makeself.sh 2>/dev/null || true`

if [ -z "$MAKESELF" ]
then
	git clone https://github.com/megastep/makeself.git
	export PATH=`pwd`/makeself:$PATH
	MAKESELF=`which makeself.sh 2>/dev/null || true`
fi

$MAKESELF --notemp out-of-one-many ooom.run "Out of one, many: Move directories to different partitions"

popd >/dev/null

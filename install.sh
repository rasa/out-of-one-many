#!/usr/bin/env bash

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

OOOM_RC_LOCAL=/etc/rc.local.ooomed

if [ -f "$OOOM_RC_LOCAL" ]
then
	echo ooom has already been installed.
	exit 1
fi

sudo cp -p $OOOM_DIR/ooom*.sh $OOOM_DIR/ooom*.fstab /etc

if [ -f /etc/rc.local ]
then
	sudo mv -f /etc/rc.local $OOOM_RC_LOCAL
else
	OOOM_RC_LOCAL=
fi

echo /etc/ooom.sh | sudo tee /etc/rc.local >/dev/null

sudo chmod a+x /etc/rc.local

sudo update-rc.d rc.local enable

echo ooom has been installed into /etc/rc.local.

echo The original /etc/rc.local has been saved to $OOOM_RC_LOCAL
echo and will be restored when ooom has finished processing.

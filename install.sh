#!/usr/bin/env bash

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

sudo cp -p $OOOM_DIR/ooom*.sh $OOOM_DIR/ooom.fstab /etc

echo -e "\n/etc/ooom.sh\n" | sudo tee -a /etc/rc.local >/dev/null

echo ooom has been installed.

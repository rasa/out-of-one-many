#!/usr/bin/env bash

OOOM_DIR="$(cd "$(dirname "$0")"; pwd)"

sudo cp -p $OOOM_DIR/ooom*.sh $OOOM_DIR/ooom.fstab /etc

sudo perl -pi.orig -e 's|^(\s*exit\s+0\s*)$|#\1|' /etc/rc.local

echo -e "\n/etc/ooom.sh\nexit 0\n" | sudo tee -a /etc/rc.local >/dev/null

echo ooom has been installed.

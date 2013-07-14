#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

sudo cp -p $SCRIPT_DIR/ooom*.sh /etc

echo -e "\n/etc/ooom.sh\n" | sudo tee -a /etc/rc.local >/dev/null

echo ooom has been installed.

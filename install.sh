#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

sudo cp -p $SCRIPT_DIR/ooom*.sh /etc

echo | sudo tee -a /etc/rc.local

echo /etc/ooom.sh | sudo tee -a /etc/rc.local

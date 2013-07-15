#!/usr/bin/env bash

sudo rm /etc/ooom*.sh

sudo perl -pi.orig -e 's|\s*#?\s*/etc/ooom\.sh.*$||' /etc/rc.local

echo ooom has been uninstalled.

#!/usr/bin/env bash

sudo rm /etc/ooom*.sh

sudo perl -pi.orig -e 's|\s*/etc/ooom\..*$||' /etc/rc.local


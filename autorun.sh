#!/usr/bin/env bash

# install ooom and reboot

sudo ./install.sh $* && sudo shutdown -r now

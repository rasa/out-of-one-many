#!/usr/bin/env bash

# uninstall ooom

sudo rm /etc/ooom*.sh

OOOM_RC_LOCAL=/etc/rc.local.ooomed

if [[ -f "$OOOM_RC_LOCAL" ]]; then
  sudo cp -p "$OOOM_RC_LOCAL" /etc/rc.local
  sudo chmod a+x /etc/rc.local
else
  sudo rm -f /etc/rc.local
fi

echo ooom has been uninstalled.

echo The original /etc/rc.local has been restored.

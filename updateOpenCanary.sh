#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

#sudo bash raspberrypi/updateOpenCanary.sh

updateOpenCanaryScriptName="updateOpenCanary.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

if [ -z ${includeScriptName+x} ]; then
  source "${SCRIPT_DIR}/include.sh"
fi

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echoError "user" "not running as root"
  exit 1
fi

if [ -z ${configScriptName+x} ]; then
  source "${SCRIPT_DIR}/configs.sh"
fi

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

if [ -z ${setupOpenCanaryScriptName+x} ]; then
  source "${SCRIPT_DIR}/setupOpenCanary.sh"
fi

echoInfo "script" "* Upgrading Open Canary *"

cd /home/pi/OpenCanary || exit 100
. env/bin/activate || exit 100

sudo systemctl stop opencanary || exit 100

pip install opencanary --upgrade || exit 100

sudo systemctl daemon-reload || exit 100
sudo systemctl restart rsyslog || exit 100
sudo systemctl restart syslog || exit 100
sudo smbcontrol all reload-config || exit 100
sudo systemctl restart smbd || exit 100
sudo systemctl restart nmbd || exit 100

sudo systemctl enable opencanary.service || exit 100
sudo systemctl start opencanary || exit 100
sudo systemctl status opencanary || exit 100

sudo systemctl enable opencanarylistener.service || exit 100
sudo systemctl start opencanarylistener || exit 100
sudo systemctl status opencanarylistener || exit 100

#!/usr/bin/env bash

#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

updateFirmwareScriptName="updateFirmware.sh"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z ${includeScriptName+x} ]; then
  source "${SCRIPT_DIR}/include.sh"
fi

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echoError "user" "not running as root"
  exit 1
fi

echoInfo "OS" "Updating..."
sudo apt -y update && sudo apt -y upgrade && sudo apt -y autoremove || exit 100

echoInfo "Firmware" "Updating..."
sudo rpi-eeprom-update || exit 100
sudo apt full-upgrade || exit 100
sudo apt install rpi-eeprom || exit 100
sudo rpi-eeprom-update -a || exit 100

echoWarning "script" "reboot if something was updated!"

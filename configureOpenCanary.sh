#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureOpenCanaryScriptName="configureOpenCanary.sh"

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

echoInfo "script" "* Installing Open Canary *"
sudo /home/pi/OpenCanary/env/bin/opencanaryd --stop
sudo systemctl stop opencanary

sudo apt install -y python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev
sudo apt install -y samba # if you plan to use the smb module

sudo mkdir -p /home/pi/OpenCanary
cd /home/pi/OpenCanary || exit 100

virtualenv env/
. env/bin/activate

sudo systemctl restart rsyslog
sudo systemctl restart syslog
sudo smbcontrol all reload-config
sudo systemctl restart smbd
sudo systemctl restart nmbd

pip install opencanary
pip install scapy pcapy # optional

sudo systemctl enable opencanary.service
sudo systemctl start opencanary
sudo systemctl status opencanary

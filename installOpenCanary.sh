#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
installOpenCanaryScriptName="installOpenCanary.sh"

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

echoInfo "script" "Configuring iptables"
sudo apt install -y iptables || exit 100
sudo iptables -D INPUT -j LOG
sudo iptables -A INPUT -j LOG || exit 100
sudo iptables -D FORWARD -j LOG
sudo iptables -A FORWARD -j LOG || exit 100
sudo ip6tables -D INPUT -j LOG
sudo ip6tables -A INPUT -j LOG || exit 100
sudo ip6tables -D FORWARD -j LOG
sudo ip6tables -A FORWARD -j LOG || exit 100

echoInfo "script" "* Installing Open Canary *"
sudo /home/pi/OpenCanary/env/bin/opencanaryd --stop
sudo systemctl stop opencanary

sudo apt install -y python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev jq samba

sudo mkdir -p /home/pi/OpenCanary
cd /home/pi/OpenCanary || exit 100

virtualenv env/
. env/bin/activate

pip install opencanary
pip install scapy pcapy # optional

sudo systemctl daemon-reload || exit 100
sudo systemctl restart rsyslog || exit 100
sudo systemctl restart syslog || exit 100
sudo smbcontrol all reload-config || exit 100
sudo systemctl restart smbd || exit 100
sudo systemctl restart nmbd || exit 100

sudo systemctl enable opencanarylistener.service || exit 100
sudo systemctl start opencanarylistener || exit 100
sudo systemctl status opencanarylistener || exit 100

sudo systemctl enable opencanary.service
sudo systemctl start opencanary
sudo systemctl status opencanary

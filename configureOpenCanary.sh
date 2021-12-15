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

if [ -z ${reportPsadTo+x} ]; then
  echoError "configs.sh" "var reportPsadTo is unset"
  exit 100
else
  echoInfo "configs.sh" "reportPsadTo is set to '${reportPsadTo}'"
fi

if [ -z ${deviceHostname+x} ]; then
  echoError "configs.sh" "var deviceHostname is unset"
  exit 100
else
  echoInfo "configs.sh" "var deviceHostname is set to '${deviceHostname}'"
fi

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

echoInfo "script" "* Configuring Open Canary *"
sudo apt-get install python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev
sudo apt install samba # if you plan to use the smb module
virtualenv env/
. env/bin/activate
pip install opencanary
pip install scapy pcapy # optional

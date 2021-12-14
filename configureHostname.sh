#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureHostnameScriptName="configureHostname.sh"

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

echoInfo "configs.sh" "variable loading"

if [ -z ${deviceHostname+x} ]; then
  echoError "configs.sh" "var deviceHostname is unset"
  exit 100
else
  echoInfo "configs.sh" "var deviceHostname is set to '${deviceHostname}'"
fi

echoInfo "/etc/hostname" "editing.."
sudo sed -i "s/^raspberr[iy]\(pi\)*$/${deviceHostname}/g" "/etc/hostname"

echoInfo "/etc/hosts" "editing.."
sudo sed -i "s/raspberr[iy]\(pi\)*/${deviceHostname}/g" "/etc/hosts"

echoWarning "script" "remember to reboot!"

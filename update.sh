#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
updateScriptName="update.sh"

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

echoInfo "OS" "Updating..."
sudo apt -y update && sudo apt -y upgrade && sudo apt -y autoremove || exit 100
echoInfo "OS" "Updating psad..."
sudo psad --sig-update || exit 100

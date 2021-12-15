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

echoInfo "script" "* Update *"

if [ -z ${configScriptName+x} ]; then
  source "${SCRIPT_DIR}/configs.sh"
fi

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

if [ -z ${updateFirmwareScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateFirmware.sh"
fi

if [ -z ${updatePsadScriptName+x} ]; then
  source "${SCRIPT_DIR}/updatePsad.sh"
fi

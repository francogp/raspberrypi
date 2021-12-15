#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureAllScriptName="configureAll.sh"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

if [ -z ${configureHostnameScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureHostname.sh"
fi

if [ -z ${configureIPScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureIP.sh"
fi

if [ -z ${configureIPScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureIP.sh"
fi

if [ -z ${configureIptableScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureIptable.sh"
fi

#already executed on configureIptable
#if [ -z ${configurePsadScriptName+x} ]; then
#  source "${SCRIPT_DIR}/configurePsad.sh"
#fi

if [ -z ${updateFirmwareScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateFirmware.sh"
fi

#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
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

echoInfo "script" "* Configuring ALL *"

sudo chown root:root "${SCRIPT_DIR}/../raspberrypi" || exit 100
sudo chmod 700 "${SCRIPT_DIR}/../raspberrypi" || exit 100

if [ -z ${configureHostnameScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureHostname.sh"
fi

if [ -z ${configureIPScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureIP.sh"
fi

if [ -z ${configureMailScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureMail.sh"
fi

if [ -z ${configureIpTableScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureIpTable.sh"
fi

if [ -z ${configureSSHScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureSSH.sh"
fi

#if [ -z ${installPsadScriptName+x} ]; then
#  source "${SCRIPT_DIR}/installPsad.sh"
#fi

if [ -z ${installOpenCanaryScriptName+x} ]; then
  source "${SCRIPT_DIR}/installOpenCanary.sh"
fi

if [ -z ${updateFirmwareScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateFirmware.sh"
fi

if [ -z ${configureCrontabScriptName+x} ]; then
  source "${SCRIPT_DIR}/configureCrontab.sh"
fi

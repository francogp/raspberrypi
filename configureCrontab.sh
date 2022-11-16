#!/usr/bin/env bash
#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

# sudo bash raspberrypi/configureCrontab.sh

configureCrontabScriptName="configureCrontab.sh"

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

  echoInfo "script" "Configuring Cron"

  echo "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=\"\"

0 6 * * MON root /bin/bash ${SCRIPT_DIR}/update.sh 2>&1 > /dev/null
" >/etc/cron.d/myScripts || exit 100

echoInfo "script" "refreshing cron"
sudo service cron reload || exit 100
sudo service cron status || exit 100
echoInfo "script" "using the script:"
sudo cat /etc/cron.d/myScripts || exit 100
echoInfo "script" "success"

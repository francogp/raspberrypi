#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureMailScriptName="configureMail.sh"

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


if [ -z ${mailFullName+x} ]; then
  echoError "configs.sh" "var mailFullName is unset"
  exit 100
else
  echoInfo "configs.sh" "mailFullName is set to '${mailFullName}'"
fi

if [ -z ${mailAddress+x} ]; then
  echoError "configs.sh" "var mailAddress is unset"
  exit 100
else
  echoInfo "configs.sh" "mailAddress is set to '${mailAddress}'"
fi

if [ -z ${mailPassword+x} ]; then
  echoError "configs.sh" "var mailPassword is unset"
  exit 100
else
  echoInfo "configs.sh" "mailPassword is set to '******'"
fi

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

echoInfo "script" "installing"
sudo rm /root/.muttrc
sudo rm /home/franco/.muttrc
apt-get -y install msmtp mutt || exit 100

#------------------------------------------------------------------

echoInfo "script" "msmtp config..."

echo "# Set default values for all following accounts.
defaults
  protocol       smtp
  auth           on
  tls            on
  tls_starttls   on
  logfile        /var/log/msmtp

# ${mailFullName} en cevt.ar
account server
  host           smtp.cevt.ar
  port           587
  user           ${mailAddress}
  from           ${mailAddress}
  password       ${mailPassword}

# Set a default account
account default : server
" >/etc/msmtprc

sudo chmod 600 /etc/msmtprc

echoInfo "script" "Mutt config..."

configs="
set sendmail=\"/usr/bin/msmtp --account=server\"

set edit_headers=yes
set use_from=yes
set envelope_from=yes

set realname=\"${mailFullName}\"
set from=\"${mailAddress}\"
"
echo "${configs}" >/etc/Muttrc

echoInfo "script" "DONE!"

echoInfo "script" "test to do:"
# shellcheck disable=SC2016
echo 'echo "hola como estas $(( ( RANDOM % 10 )  + 1 ))" | sudo msmtp -a default francogpellegrini@gmail.com'
# shellcheck disable=SC2016
echo 'echo "hola como estas $(( ( RANDOM % 10 )  + 1 ))" | sudo mutt -s "TEST $(( ( RANDOM % 10 )  + 1 ))" -- francogpellegrini@gmail.com'
# shellcheck disable=SC2016
echo 'echo test | mail -s "Envío de prueba al root del sistema" -a "From: Franco <server-developer@cevt.ar>" desarrollo-it@cevt.ar'

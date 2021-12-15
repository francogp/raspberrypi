#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configurePsadScriptName="configurePsad.sh"

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

echoInfo "script" "Configuring PSAD"
sudo apt install -y psad || exit 100
sudo sed -i "s/^EMAIL_ADDRESSES\s\+.*$/EMAIL_ADDRESSES             ${reportPsadTo};/g" "/etc/psad/psad.conf"
sudo sed -i "s/^HOSTNAME\s\+.*$/HOSTNAME                    ${deviceHostname};/g" "/etc/psad/psad.conf"
sudo sed -i "s/^ALERT_ALL\s\+.*$/ALERT_ALL                   N;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^EMAIL_ALERT_DANGER_LEVEL\s\+.*$/EMAIL_ALERT_DANGER_LEVEL                   2;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^PORT_RANGE_SCAN_THRESHOLD\s\+.*$/PORT_RANGE_SCAN_THRESHOLD                   2;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^mailCmd\s\+.*$/mailCmd          \/usr\/bin\/mutt\;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^sendmailCmd\s\+.*$/sendmailCmd      \/usr\/bin\/mutt\;/g" "/etc/psad/psad.conf"

function ignoreIP() {
  grep -q "^${1}\s\+0;" "/etc/psad/auto_dl" || (echo "${1}        0;" | sudo tee -a "/etc/psad/auto_dl");
  echo "${1}"
}
echoInfo "script" "Ignoring some ips"
ignoreIP '192.168.0.120'
ignoreIP '192.168.1.120'
ignoreIP '8.8.4.4'
#grep -q '^192.168.0.120\s\+0;' "/etc/psad/auto_dl" || (echo '192.168.0.120        0;' | sudo tee -a "/etc/psad/auto_dl")
#grep -q '^192.168.1.120\s\+0;' "/etc/psad/auto_dl" || (echo '192.168.1.120        0;' | sudo tee -a "/etc/psad/auto_dl")
#grep -q '^192.168.1.120\s\+0;' "/etc/psad/auto_dl" || (echo '192.168.1.120        0;' | sudo tee -a "/etc/psad/auto_dl")

psad --sig-update || exit 100

sudo service psad restart
sudo psad -S

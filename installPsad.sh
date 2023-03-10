#!/usr/bin/env bash
#
# Copyright (c) 2023. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
installPsadScriptName="installPsad.sh"

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

echoInfo "script" "* Configuring PSAD *"

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
sudo sed -i "s/^PORT_RANGE_SCAN_THRESHOLD\s\+.*$/PORT_RANGE_SCAN_THRESHOLD                   1;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^mailCmd\s\+.*$/mailCmd          \/usr\/bin\/mutt\;/g" "/etc/psad/psad.conf"
sudo sed -i "s/^sendmailCmd\s\+.*$/sendmailCmd      \/usr\/bin\/mutt\;/g" "/etc/psad/psad.conf"

echoInfo "script" "Ignoring some ips"
echo "
#
#############################################################################
#
# This file is used by psad to elevate/decrease the danger levels of IP
# addresses (or networks in CIDR notation) so that psad does not have to
# apply the normal signature logic.  This is useful if certain IP addresses
# or networks are known trouble makers and should automatically be assigned
# higher danger levels than would normally be assigned.  Also, psad can be
# made to ignore certain IP addresses or networks if a danger level of "0" is
# specified.  Optionally, danger levels for IPs/networks can be influenced
# based on protocol (tcp, udp, icmp).
#
#############################################################################
#

#  <IP address>  <danger level>  <optional protocol>/<optional ports>;
#
# Examples:
#
#  10.111.21.23     5;                # Very bad IP.
#  127.0.0.1        0;                # Ignore this IP.
#  10.10.1.0/24     0;                # Ignore traffic from this entire class C.
#  192.168.10.4     3    tcp;         # Assign danger level 3 if protocol is tcp.
#  10.10.1.0/24     3    tcp/1-1024;  # Danger level 3 for tcp port range

192.168.0.255      0    udp/137-139;
192.168.1.255      0    udp/137-139;
192.168.0.120      0;
192.168.1.120      0;
8.8.8.8            0;
8.8.4.4            0;
" > "/etc/psad/auto_dl"

psad --sig-update || exit 100

sudo service psad restart
sudo psad -S

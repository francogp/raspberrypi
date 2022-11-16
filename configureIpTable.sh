#!/usr/bin/env bash
#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureIpTableScriptName="configureIpTable.sh"

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

echoInfo "script" "* Configuring IpTable *"

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

sudo apt install -y curl grep ipset iptables sed zip unzip iptables-persistent iprange || exit 100

#disable to prefere ufw rules
sudo systemctl disable netfilter-persistent || exit 100
sudo mkdir -p /etc/iptablesiptables/

#create whitelist and blacklist
sudo ipset create blacklist -exist hash:net family inet hashsize 4096 maxelem 131072
sudo ipset create whitelist -exist hash:net family inet hashsize 4096 maxelem 131072
sudo iptables -I INPUT 1 -m set --match-set blacklist src -j DROP
sudo iptables -I INPUT 1 -m set --match-set whitelist src -j ACCEPT
#psad rules
sudo iptables -D INPUT -j LOG
sudo iptables -A INPUT -j LOG || exit 100
sudo iptables -D FORWARD -j LOG
sudo iptables -A FORWARD -j LOG || exit 100
sudo ip6tables -D INPUT -j LOG
sudo ip6tables -A INPUT -j LOG || exit 100
sudo ip6tables -D FORWARD -j LOG
sudo ip6tables -A FORWARD -j LOG || exit 100

#save lists
sudo ipset save -f /etc/iptables/ipset

#configure autoreload on boot
echo "
[Unit]
Description=ipset persistent configuration
#
DefaultDependencies=no
Before=network.target

# ipset sets should be loaded before iptables
# Because creating iptables rules with names of non-existent sets is not possible
Before=netfilter-persistent.service
Before=ufw.service

ConditionFileNotEmpty=/etc/iptables/ipset

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ipset restore -f -! /etc/iptables/ipset
ExecStartPost=/sbin/iptables -I INPUT 1 -m set --match-set blacklist src -j DROP
ExecStartPost=/sbin/iptables -I INPUT 1 -m set --match-set whitelist src -j ACCEPT
ExecStartPost=/sbin/iptables -A INPUT -j LOG
ExecStartPost=/sbin/iptables -A FORWARD -j LOG
ExecStartPost=/sbin/ip6tables -A INPUT -j LOG
ExecStartPost=/sbin/ip6tables -A FORWARD -j LOG
ExecStop=/sbin/ipset save -f /etc/iptables/ipset
ExecStop=/sbin/ipset flush
ExecStopPost=/sbin/ipset destroy

[Install]
WantedBy=multi-user.target

RequiredBy=netfilter-persistent.service
RequiredBy=ufw.service
" >"/etc/systemd/system/ipset-persistent.service"

sudo systemctl daemon-reload || exit 100
sudo systemctl enable ipset-persistent.service || exit 100

#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureIPScriptName="configureIP.sh"

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

if [ -z ${useDHCP+x} ]; then
  echoError "configs.sh" "var useDHCP is unset"
  exit 100
else
  echoInfo "configs.sh" "useDHCP is set to '$useDHCP'"
fi

if [ "${useDHCP}" == "OFF" ]; then
  if [ -z ${internetIP+x} ]; then
    echoError "configs.sh" "var internetIP is unset"
    exit 100
  else
    echoInfo "configs.sh" "internetIP is set to '$internetIP'"
  fi
  if [ -z ${internetIPMask+x} ]; then
    echoError "configs.sh" "var internetIPMask is unset"
    exit 100
  else
    echoInfo "configs.sh" "internetIPMask is set to '$internetIPMask'"
  fi
  if [ -z ${internetIPGateway+x} ]; then
    echoError "configs.sh" "var internetIPGateway is unset"
    exit 100
  else
    echoInfo "configs.sh" "internetIPGateway is set to '$internetIPGateway'"
  fi
  if [ -z ${administrativeIP+x} ]; then
    echoError "configs.sh" "var administrativeIP is unset"
    exit 100
  else
    echoInfo "configs.sh" "administrativeIP is set to '$administrativeIP'"
  fi
  if [ -z ${administrativeIPMask+x} ]; then
    echoError "configs.sh" "var administrativeIPMask is unset"
    exit 100
  else
    echoInfo "configs.sh" "administrativeIPMask is set to '$administrativeIPMask'"
  fi
fi

echoInfo "ipv6" "turning OFF"

#net.ipv6.conf.all.disable_ipv6 = 1
grep -q '^net.ipv6.conf.all.disable_ipv6 = ' /etc/sysctl.conf || (echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf)
sudo sed -i "s/^net.ipv6.conf.all.disable_ipv6.*=.*$/net.ipv6.conf.all.disable_ipv6 = 1/g" "/etc/sysctl.conf"

#net.ipv6.conf.default.disable_ipv6 = 1
grep -q '^net.ipv6.conf.default.disable_ipv6 = ' /etc/sysctl.conf || (echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf)
sudo sed -i "s/^net.ipv6.conf.default.disable_ipv6.*=.*$/net.ipv6.conf.default.disable_ipv6 = 1/g" "/etc/sysctl.conf"

#net.ipv6.conf.lo.disable_ipv6 = 1
grep -q '^net.ipv6.conf.lo.disable_ipv6 = ' /etc/sysctl.conf || (echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf)
sudo sed -i "s/^net.ipv6.conf.lo.disable_ipv6.*=.*$/net.ipv6.conf.lo.disable_ipv6 = 1/g" "/etc/sysctl.conf"

if [ "${useDHCP}" == "OFF" ]; then
  echoInfo "Interfaces" "Disabling raspberry IP management"

  grep -q '^denyinterfaces eth0$' /etc/dhcpcd.conf || (echo $'denyinterfaces eth0\nnoipv6' | sudo tee -a /etc/dhcpcd.conf)

  echoInfo "interfaces.d" "Creating custom ethernet interfaces"

  #sudo nano /etc/network/interfaces.d/eth0-administrativo
  echo "auto eth0
allow-hotplug eth0
iface eth0 inet static
    address ${internetIP}
    netmask ${internetIPMask}
    gateway ${internetIPGateway}

auto eth0:1
allow-hotplug eth0:1
iface eth0:1 inet static
    address ${administrativeIP}
    netmask ${administrativeIPMask}
" | sudo tee /etc/network/interfaces.d/eth0-administrativo

  #    add DNS
  echo "nameserver 8.8.8.8
nameserver 8.8.4.4
" | sudo tee /etc/resolv.conf
else
  echoInfo "script" "using default DHCP"
fi

echoWarning "script" "remember to reboot!"

#!/usr/bin/env bash
#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureSSHScriptName="configureSSH.sh"

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
#sudo bash configureSsh.sh on|off

#------------------------------------------------------------------

flags=("$@") # Rebuild the array with rest of arguments

if [[ "${flags[*]}" =~ "on" ]]; then
  ON=true
else
  ON=false
fi

if [[ "${flags[*]}" =~ "off" ]]; then
  OFF=true
else
  OFF=false
fi

if [[ "${flags[*]}" =~ "install" ]]; then
  INSTALL=true
else
  INSTALL=false
fi

if [ "${ON}" = false ] && [ "${OFF}" = false ]; then
  echoInfo "optional parameters" "using DEFAULT ON"
  ON=true
fi


if [[ "${flags[*]}" =~ "help" ]]; then
  echoInfo "optional parameters" "<on|off> <install>"
  exit 0
fi

#------------------------------------------------------------------
if [ -d "/home/${USER}/.ssh/" ]; then
  #add to server.
  eval $(ssh-agent -s)
  if [ "${INSTALL}" = true ]; then
    sudo chmod 700 "/home/${USER}/.ssh/"
    sudo chmod 644 "/home/${USER}/.ssh/id_rsa.pub"
    sudo chmod 600 "/home/${USER}/.ssh/id_rsa"
    ssh-add "/home/${USER}/.ssh/id_rsa"
  fi
fi

echoInfo "off" "turning off ssh"
sudo systemctl stop ssh

if [ "${ON}" = true ]; then
  echoInfo "on" "turning on ssh security"
  sudo sed -i "s/^\#Port .*$/Port 60666/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#PermitRootLogin prohibit\-password$/PermitRootLogin prohibit-password/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#MaxAuthTries.*$/MaxAuthTries 6/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#MaxSessions.*$/MaxSessions 10/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#PubkeyAuthentication.*$/PubkeyAuthentication yes/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#PasswordAuthentication.*$/PasswordAuthentication no/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\#PermitEmptyPasswords.*$/PermitEmptyPasswords no/g" "/etc/ssh/sshd_config"

  sudo sed -i "s/^ChallengeResponseAuthentication.*$/ChallengeResponseAuthentication no/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^#AuthorizedKeysFile.*$/AuthorizedKeysFile  \.ssh\/authorized_keys/g" "/etc/ssh/sshd_config"
fi

if [ "${OFF}" = true ]; then
  echoInfo "off" "turning off ssh security"
  sudo service ssh stop
  sudo sed -i "s/^\PermitRootLogin prohibit\-password$/#PermitRootLogin prohibit-password/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\PasswordAuthentication.*$/#PasswordAuthentication no/g" "/etc/ssh/sshd_config"
  sudo sed -i "s/^\PermitEmptyPasswords.*$/#PermitEmptyPasswords no/g" "/etc/ssh/sshd_config"
fi

sudo systemctl enable ssh.service
sudo service sshd restart
echoInfo "script" "status"
sudo systemctl status ssh

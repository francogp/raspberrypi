#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#
configureOpenCanaryScriptName="configureOpenCanary.sh"

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

if [ -z ${reportOpenCanaryTo+x} ]; then
  echoError "configs.sh" "var reportOpenCanaryTo is unset"
  exit 100
else
  echoInfo "configs.sh" "reportOpenCanaryTo is set to '${reportOpenCanaryTo}'"
fi

if [ -z ${reportIpToIgnoreOpenCanaryTo+x} ]; then
  echoError "configs.sh" "var reportIpToIgnoreOpenCanaryTo is unset"
  exit 100
else
  echoInfo "configs.sh" "reportIpToIgnoreOpenCanaryTo is set to '${reportIpToIgnoreOpenCanaryTo}'"
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

if [ -z ${deviceHostname+x} ]; then
  echoError "configs.sh" "var deviceHostname is unset"
  exit 100
else
  echoInfo "configs.sh" "var deviceHostname is set to '${deviceHostname}'"
fi

if [ -z ${updateOsScriptName+x} ]; then
  source "${SCRIPT_DIR}/updateOS.sh"
fi

echoInfo "script" "* Configuring Open Canary *"
sudo /home/pi/OpenCanary/env/bin/opencanaryd --stop
sudo systemctl stop opencanary

sudo apt install -y python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev
sudo apt install -y samba # if you plan to use the smb module

sudo mkdir -p /home/pi/OpenCanary
cd /home/pi/OpenCanary || exit 100

virtualenv env/
. env/bin/activate

# shellcheck disable=SC2016
echo "
{
  \"device.node_id\": \"${deviceHostname}\",
  \"ip.ignorelist\": [ ${reportIpToIgnoreOpenCanaryTo} ],
  \"git.enabled\": true,
  \"git.port\" : 9418,
  \"ftp.enabled\": true,
  \"ftp.port\": 21,
  \"ftp.banner\": \"FTP server ready\",
  \"http.banner\": \"Apache/2.2.22 (Ubuntu)\",
  \"http.enabled\": true,
  \"http.port\": 80,
  \"http.skin\": \"nasLogin\",
  \"httpproxy.enabled\" : true,
  \"httpproxy.port\": 8080,
  \"httpproxy.skin\": \"squid\",
  \"logger\": {
      \"class\": \"PyLogger\",
        \"kwargs\": {
          \"formatters\": {
            \"plain\": {
              \"format\": \"%(message)s\"
            },
            \"syslog_rfc\": {
              \"format\": \"opencanaryd[%(process)-5s:%(thread)d]: %(name)s %(levelname)-5s %(message)s\"
            }
          },
          \"handlers\": {
            \"console\": {
            \"class\": \"logging.StreamHandler\",
            \"stream\": \"ext://sys.stdout\"
          },
          \"file\": {
            \"class\": \"logging.FileHandler\",
            \"filename\": \"/var/tmp/opencanary.log\"
          },
          \"SMTP\": {
            \"class\": \"logging.handlers.SMTPHandler\",
            \"mailhost\": [\"smtp.cevt.ar\", 587],
            \"fromaddr\": \"${mailFullName} <${mailAddress}>\",
            \"toaddrs\" : [${reportOpenCanaryTo}],
            \"subject\" : \"OpenCanary Alert\",
            \"credentials\" : [\"${mailAddress}\", \"${mailPassword}\"],
            \"secure\" : []
          }
        }
      }
  },
  \"portscan.enabled\": true,
  \"portscan.ignore_localhost\": true,
  \"portscan.logfile\":\"/var/log/kern.log\",
  \"portscan.synrate\": 5,
  \"portscan.nmaposrate\": 5,
  \"portscan.lorate\": 3,
  \"smb.auditfile\": \"/var/log/samba-audit.log\",
  \"smb.enabled\": true,
  \"mysql.enabled\": true,
  \"mysql.port\": 3306,
  \"mysql.banner\": \"5.5.43-0ubuntu0.14.04.1\",
  \"ssh.enabled\": true,
  \"ssh.port\": 22,
  \"ssh.version\": \"SSH-2.0-OpenSSH_5.1p1 Debian-4\",
  \"redis.enabled\": true,
  \"redis.port\": 6379,
  \"rdp.enabled\": true,
  \"rdp.port\": 3389,
  \"sip.enabled\": true,
  \"sip.port\": 5060,
  \"snmp.enabled\": true,
  \"snmp.port\": 161,
  \"ntp.enabled\": true,
  \"ntp.port\": 123,
  \"tftp.enabled\": true,
  \"tftp.port\": 69,
  \"tcpbanner.maxnum\":10,
  \"tcpbanner.enabled\": false,
  \"tcpbanner_1.enabled\": false,
  \"tcpbanner_1.port\": 8001,
  \"tcpbanner_1.datareceivedbanner\": \"\",
  \"tcpbanner_1.initbanner\": \"\",
  \"tcpbanner_1.alertstring.enabled\": false,
  \"tcpbanner_1.alertstring\": \"\",
  \"tcpbanner_1.keep_alive.enabled\": false,
  \"tcpbanner_1.keep_alive_secret\": \"\",
  \"tcpbanner_1.keep_alive_probes\": 11,
  \"tcpbanner_1.keep_alive_interval\":300,
  \"tcpbanner_1.keep_alive_idle\": 300,
  \"telnet.enabled\": true,
  \"telnet.port\": 23,
  \"telnet.banner\": \"\",
  \"telnet.honeycreds\": [
    {
      \"username\": \"admin\",
      \"password\": \"\$pbkdf2-sha512\$19000\$bG1NaY3xvjdGyBlj7N37Xw\$dGrmBqqWa1okTCpN3QEmeo9j5DuV2u1EuVFD8Di0GxNiM64To5O/Y66f7UASvnQr8.LCzqTm6awC8Kj/aGKvwA\"
    },
    {
      \"username\": \"admin\",
      \"password\": \"admin1\"
    }
  ],
  \"mssql.enabled\": true,
  \"mssql.version\": \"2012\",
  \"mssql.port\":1433,
  \"vnc.enabled\": true,
  \"vnc.port\":5000
}
" > /etc/opencanaryd/opencanary.conf

sudo chown -R root:root /etc/opencanaryd/opencanary.conf

sudo mkdir -p /home/pi/samba
sudo chown pi:pi /home/pi/samba
sudo touch /home/pi/samba/testing.txt

echo '
[global]
   workgroup = WORKGROUP
   server string = NBDocs
   netbios name = SRV01
   dns proxy = no
   log file = /var/log/samba/log.all
   log level = 0
   max log size = 100
   panic action = /usr/share/samba/panic-action %d
   #samba 4
   server role = standalone server
   #samba 3
   #security = user
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = no
   map to guest = bad user
   usershare allow guests = yes
   load printers = no
   vfs object = full_audit
   full_audit:prefix = %U|%I|%i|%m|%S|%L|%R|%a|%T|%D
   full_audit:success = pread_recv pread_send
   full_audit:failure = none
   full_audit:facility = local7
   full_audit:priority = notice
[myshare]
   comment = All the stuff!
   path = /home/pi/samba
   guest ok = yes
   read only = yes
   browseable = yes
 ' > '/etc/samba/smb.conf'

grep -q '^local7.*/var/log/samba-audit.log' /etc/rsyslog.conf || (echo 'local7.* /var/log/samba-audit.log' | sudo tee -a /etc/rsyslog.conf)
sudo touch /var/log/samba-audit.log
sudo chown root:adm /var/log/samba-audit.log

sudo systemctl restart rsyslog
sudo systemctl restart syslog
sudo smbcontrol all reload-config
sudo systemctl restart smbd
sudo systemctl restart nmbd

echo "
[Unit]
Description=OpenCanary
After=syslog.target
After=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
ExecStart=/home/pi/OpenCanary/env/bin/opencanaryd --start
ExecStop=/home/pi/OpenCanary/env/bin/opencanaryd --stop

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/opencanary.service

echoInfo "script" "* Installing Open Canary *"

pip install opencanary
pip install scapy pcapy # optional

sudo systemctl enable opencanary.service
sudo systemctl start opencanary
sudo systemctl status opencanary

#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

#sudo bash raspberrypi/listenerOpenCanary.sh

# ======== START configs ========
MSG_UNTIL_SEND_MAIL=10
LOW_DANGER_MSG_GE_THAN=2000
# ======== END configs ========

listenerOpenCanaryScriptName="listenerOpenCanary.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

#if [[ $(/usr/bin/id -u) -ne 0 ]]; then
#  echo "not running as root"
#  exit 1
#fi

if [ -z ${configScriptName+x} ]; then
  source "${SCRIPT_DIR}/configs.sh"
fi

if [ -z ${reportOpenCanaryLowDangerTo+x} ]; then
  echo "var reportOpenCanaryLowDangerTo is unset"
  exit 100
else
  echo "reportOpenCanaryLowDangerTo is set to '${reportOpenCanaryLowDangerTo}'"
fi

if [ -z ${reportOpenCanaryDangerTo+x} ]; then
  echo "var reportOpenCanaryDangerTo is unset"
  exit 100
else
  echo "reportOpenCanaryDangerTo is set to '${reportOpenCanaryDangerTo}'"
fi

declare -A LogTypes
LogTypes=(
  ["1000"]="BASE BOOT"
  ["1001"]="BASE MSG"
  ["1002"]="BASE DEBUG"
  ["1003"]="BASE ERROR"
  ["1004"]="BASE PING"
  ["1005"]="BASE CONFIG SAVE"
  ["1006"]="BASE EXAMPLE"
  ["2000"]="FTP LOGIN ATTEMPT"
  ["3000"]="HTTP GET"
  ["3001"]="HTTP POST LOGIN ATTEMPT"
  ["4000"]="SSH NEW CONNECTION"
  ["4001"]="SSH REMOTE VERSION SENT"
  ["4002"]="SSH LOGIN ATTEMPT"
  ["5000"]="SMB FILE OPEN"
  ["5001"]="PORT SYN"
  ["5002"]="PORT NMAP OS"
  ["5003"]="PORT NMAP NULL"
  ["5004"]="PORT NMAP XMAS"
  ["5005"]="PORT NMAP FIN"
  ["6001"]="TELNET LOGIN ATTEMPT"
  ["7001"]="HTTPPROXY LOGIN ATTEMPT"
  ["8001"]="MYSQL LOGIN ATTEMPT"
  ["9001"]="MSSQL LOGIN SQL AUTH"
  ["9002"]="MSSQL LOGIN WIN AUTH"
  ["10001"]="TFTP"
  ["11001"]="NTP MONLIST"
  ["12001"]="VNC"
  ["13001"]="SNMP CMD"
  ["14001"]="RDP"
  ["15001"]="SIP REQUEST"
  ["16001"]="GIT CLONE REQUEST"
  ["17001"]="REDIS COMMAND"
  ["18001"]="TCP BANNER CONNECTION MADE"
  ["18002"]="TCP BANNER KEEP ALIVE CONNECTION MADE"
  ["18003"]="TCP BANNER KEEP ALIVE SECRET RECEIVED"
  ["18004"]="TCP BANNER KEEP ALIVE DATA RECEIVED"
  ["18005"]="TCP BANNER DATA RECEIVED"
  ["99000"]="USER 0"
  ["99001"]="USER 1"
  ["99002"]="USER 2"
  ["99003"]="USER 3"
  ["99004"]="USER 4"
  ["99005"]="USER 5"
  ["99006"]="USER 6"
  ["99007"]="USER 7"
  ["99008"]="USER 8"
  ["99009"]="USER 9"

)

function cleanup() {
  echo ""
  echo "Cleaning connections..."
  sudo pkill -fx 'nc -q -1 -k -l localhost 1514'
  echo "Listening ports running:"
  sudo netstat -ltup | grep 1514
  echo "Service Stop!"
  exit 0
}

trap cleanup SIGINT

function sendMail() {
  #  echo "${LogTypes[${logType}]}"
  msg="${1}"
  dangerLevel="${2}"
#  jsonParsedLine=$(jq . <<<"${msg}")
  jsonParsedLineTable=$(jq -r '.[] | "\(.local_time)\t\(.logtype)\t\(.src_host)\t\(.src_port)\t\(.dst_host)\t\(.dst_port)\t\(.node_id)\t\(.logdata)"' <<<"${msg}")
  if [[ "$dangerLevel" -eq 0 ]]; then
    dangerMsg="Baja Importancia"
    targetMail="${reportOpenCanaryLowDangerTo}"
  else
    dangerMsg="Importante!"
    targetMail="${reportOpenCanaryDangerTo}"
  fi
  echo "DANGER LEVEL = ${dangerLevel}"
  echo "${jsonParsedLineTable}"
  echo -e "${jsonParsedLineTable}" | sudo mutt -e "set content_type=text/plain" -s "OpenCanary: ${dangerMsg}" -- "${targetMail}"
}

counterDanger=0
counterLow=0
msgDanger="["
msgLow="["
while read -r line; do
  # ======= process line =======
  logType=$(jq '.logtype' <<<"${line}")
  if [[ "$logType" -ge ${LOW_DANGER_MSG_GE_THAN} ]]; then
    # ======= append to DANGER mail =========
    msgDanger+="${line}"
    counterDanger=$((counterDanger + 1))
    if [[ "$counterDanger" -eq ${MSG_UNTIL_SEND_MAIL} ]]; then
      msgDanger+="]"
      # FORK function and continue
      sendMail "${msgDanger}" "1" &
      msgDanger="["
      counterDanger=0
    else
      msgDanger+=","
    fi
  else
    # ======= append to low mail =========
    msgLow+="${line}"
    counterLow=$((counterLow + 1))
    if [[ "$counterLow" -eq ${MSG_UNTIL_SEND_MAIL} ]]; then
      msgLow+="]"
      # FORK function and continue
      sendMail "${msgLow}" "0" &
      msgLow="["
      counterLow=0
    else
      msgLow+=","
    fi
  fi
done < <(nc -q -1 -k -l localhost 1514)

#sudo netstat -ltup | grep 1514
#jq '.' <<<  '[{"dst_host": "9.9.9.9", "dst_port": 21, "local_time": "2015-07-20 13:38:21.281259", "logdata": {"PASSWORD": "default", "USERNAME": "admin"}, "logtype": 2000, "node_id": "AlertTest","src_host": "8.8.8.8", "src_port": 49635},{"dst_host": "8.9.9.8", "dst_port": 217, "local_time": "2015-07-20 13:39:27.59", "logdata": {"PASSWORD": "default4", "USERNAME": "admin2"}, "logtype": 2001, "node_id": "AlertTest","src_host": "8.4.8.4", "src_port": 496335}]'

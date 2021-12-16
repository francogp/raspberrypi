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
  ["1000"]="LOG_BASE_BOOT"
  ["1001"]="LOG_BASE_MSG"
  ["1002"]="LOG_BASE_DEBUG"
  ["1003"]="LOG_BASE_ERROR"
  ["1004"]="LOG_BASE_PING"
  ["1005"]="LOG_BASE_CONFIG_SAVE"
  ["1006"]="LOG_BASE_EXAMPLE"
  ["2000"]="LOG_FTP_LOGIN_ATTEMPT"
  ["3000"]="LOG_HTTP_GET"
  ["3001"]="LOG_HTTP_POST_LOGIN_ATTEMPT"
  ["4000"]="LOG_SSH_NEW_CONNECTION"
  ["4001"]="LOG_SSH_REMOTE_VERSION_SENT"
  ["4002"]="LOG_SSH_LOGIN_ATTEMPT"
  ["5000"]="LOG_SMB_FILE_OPEN"
  ["5001"]="LOG_PORT_SYN"
  ["5002"]="LOG_PORT_NMAPOS"
  ["5003"]="LOG_PORT_NMAPNULL"
  ["5004"]="LOG_PORT_NMAPXMAS"
  ["5005"]="LOG_PORT_NMAPFIN"
  ["6001"]="LOG_TELNET_LOGIN_ATTEMPT"
  ["7001"]="LOG_HTTPPROXY_LOGIN_ATTEMPT"
  ["8001"]="LOG_MYSQL_LOGIN_ATTEMPT"
  ["9001"]="LOG_MSSQL_LOGIN_SQLAUTH"
  ["9002"]="LOG_MSSQL_LOGIN_WINAUTH"
  ["10001"]="LOG_TFTP"
  ["11001"]="LOG_NTP_MONLIST"
  ["12001"]="LOG_VNC"
  ["13001"]="LOG_SNMP_CMD"
  ["14001"]="LOG_RDP"
  ["15001"]="LOG_SIP_REQUEST"
  ["16001"]="LOG_GIT_CLONE_REQUEST"
  ["17001"]="LOG_REDIS_COMMAND"
  ["18001"]="LOG_TCP_BANNER_CONNECTION_MADE"
  ["18002"]="LOG_TCP_BANNER_KEEP_ALIVE_CONNECTION_MADE"
  ["18003"]="LOG_TCP_BANNER_KEEP_ALIVE_SECRET_RECEIVED"
  ["18004"]="LOG_TCP_BANNER_KEEP_ALIVE_DATA_RECEIVED"
  ["18005"]="LOG_TCP_BANNER_DATA_RECEIVED"
  ["99000"]="LOG_USER_0"
  ["99001"]="LOG_USER_1"
  ["99002"]="LOG_USER_2"
  ["99003"]="LOG_USER_3"
  ["99004"]="LOG_USER_4"
  ["99005"]="LOG_USER_5"
  ["99006"]="LOG_USER_6"
  ["99007"]="LOG_USER_7"
  ["99008"]="LOG_USER_8"
  ["99009"]="LOG_USER_9"

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
  msg="${1}"
  dangerLevel="${2}"
  jsonParsedLine=$(jq . <<<"${msg}")
  if [[ "$dangerLevel" -eq 0 ]]; then
    dangerMsg="Baja Importancia"
    targetMail="${reportOpenCanaryLowDangerTo}"
  else
    dangerMsg="Importante!"
    targetMail="${reportOpenCanaryDangerTo}"
  fi
  echo "DANGER LEVEL = ${dangerLevel}"
  echo "${jsonParsedLine}"
  echo -e "${jsonParsedLine}" | sudo mutt -e "set content_type=text/plain" -s "OpenCanary: ${dangerMsg}" -- "${targetMail}"
}

dangerLevel=0
counter=0
msg="["
while read -r line; do
  # ======= process line =======
  logType=$(jq '.logtype' <<<"${line}")
  if [[ "$logType" -ge ${LOW_DANGER_MSG_GE_THAN} ]]; then
    dangerLevel=$((dangerLevel + 1))
  fi
  #  echo "${LogTypes[${logType}]}"

  # ======= append line to mail =========
  msg+="${line}"
  counter=$((counter + 1))
  if [[ "$counter" -eq ${MSG_UNTIL_SEND_MAIL} ]]; then
    msg+="]"
    # FORK function and continue
    sendMail "${msg}" "${dangerLevel}" &
    msg="["
    counter=0
    dangerLevel=0
  else
    msg+=","
  fi
done < <(nc -q -1 -k -l localhost 1514)

#sudo netstat -ltup | grep 1514
#jq '.' <<<  '[{"dst_host": "9.9.9.9", "dst_port": 21, "local_time": "2015-07-20 13:38:21.281259", "logdata": {"PASSWORD": "default", "USERNAME": "admin"}, "logtype": 2000, "node_id": "AlertTest","src_host": "8.8.8.8", "src_port": 49635},{"dst_host": "8.9.9.8", "dst_port": 217, "local_time": "2015-07-20 13:39:27.59", "logdata": {"PASSWORD": "default4", "USERNAME": "admin2"}, "logtype": 2001, "node_id": "AlertTest","src_host": "8.4.8.4", "src_port": 496335}]'

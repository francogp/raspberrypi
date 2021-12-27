#!/usr/bin/env bash
#
# Copyright (c) 2021. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

#sudo journalctl -u opencanarylistener -b

#sudo git -C raspberrypi pull && sudo bash raspberrypi/updateOpenCanary.sh

#ps aux | grep 1514
#kill -9 70894

#test
#echo '{"dst_host": "9.9.9.9", "dst_port": 21, "local_time": "2015-07-20 13:38:21.281259", "logdata": {"PASSWORD": "default", "USERNAME": "admin"}, "logtype": 1000, "node_id": "AlertTest","src_host": "8.8.8.8", "src_port": 49635}' | nc -v -q 1 127.0.0.1 1514

#sudo netstat -ltup | grep 1514
#jq '.' <<<  '[{"dst_host": "9.9.9.9", "dst_port": 21, "local_time": "2015-07-20 13:38:21.281259", "logdata": {"PASSWORD": "default", "USERNAME": "admin"}, "logtype": 2000, "node_id": "AlertTest","src_host": "8.8.8.8", "src_port": 49635},{"dst_host": "8.9.9.8", "dst_port": 217, "local_time": "2015-07-20 13:39:27.59", "logdata": {"PASSWORD": "default4", "USERNAME": "admin2"}, "logtype": 2001, "node_id": "AlertTest","src_host": "8.4.8.4", "src_port": 496335}]'

#sudo bash raspberrypi/listenerOpenCanary.sh

# ======== START configs ========
MSG_UNTIL_SEND_MAIL=1000
LOW_DANGER_MSG_GE_THAN=2000
OPEN_CANARY_LISTEN_PORT=1514
OPEN_CANARY_MAILER_PORT=1515
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

cleanup() {
  # kill all processes whose parent is this process
  pkill -P $$
}

for sig in INT QUIT HUP TERM; do
  trap "
    cleanup
    trap - $sig EXIT
    kill -s $sig "'"$$"' "$sig"
done
trap cleanup EXIT

function periodicCommit() {
  while true; do
    #    echo "periodic commit => sleeping"
    sleep 60s
    #    echo "periodic commit => sending"
    echo -e "COMMIT!;" | nc -N -q 0 127.0.0.1 ${OPEN_CANARY_MAILER_PORT}
    #    echo "periodic commit => submitted"
  done
}

periodicCommit &

function replaceValues() {
  output="${1}"
  for i in "${!LogTypes[@]}"; do
    # shellcheck disable=SC2001
    output=$(sed -e "s/\([\"\']\)logtype[\"\']\\s*:\\s*${i}/\1logtype\1: \1${LogTypes[${i}]}\1/g" <<<"${output}")
  done
  echo "${output}"
}

function sendMail() {
  #  msg="${1}"
  echo "Email => Formatting ..."
  echo "${msg}"
  #replace known values
  msg=$(replaceValues "${1}")
  dangerLevel="${2}"
  #reformat columns to html
  jsonParsedLineTable=$(jq -r '(
map(
    {
      local_time_adjusted,
      logtype: (if .logtype == "" then "-" else .logtype end),
      proto: (if .logdata.PROTO == "" or .logdata.PROTO == null or .logdata.PROTO == "null" then "-" else .logdata.PROTO end),
      src_host: (if .src_host == "" then "-" else .src_host end),
      src_port: (if .src_port == "" or .src_port == -1 then "-" else .src_port end),
      dst_host: (if .dst_host == "" then "-" else .dst_host end),
      dst_port: (if .dst_port == "" or .dst_port == -1 then "-" else .dst_port end),
      node_id: (if .node_id == "" then "-" else .node_id end),
      logdata: (if .logdata == "" then "-" else .logdata end)
    }
  )
| .[]
| "<tr>
  <td>\(.local_time_adjusted | @html)<br></td>
  <td>\(.logtype | @html)</td>
  <td>\(.proto | @html)</td>
  <td>\(.src_host | @html)</td>
  <td>\(.src_port | @html)</td>
  <td>\(.dst_host | @html)</td>
  <td>\(.dst_port | @html)</td>
  <td>\(.node_id | @html)</td>
  <td>\(.logdata | @html)</td>
</tr>"
)' <<<"${msg}")
  plainParsedLineTable=$(jq -r '(
map(
    {
      local_time_adjusted,
      logtype: (if .logtype == "" then "-" else .logtype end),
      proto: (if .logdata.PROTO == "" or .logdata.PROTO == null or .logdata.PROTO == "null" then "-" else .logdata.PROTO end),
      src_host: (if .src_host == "" then "-" else .src_host end),
      src_port: (if .src_port == "" or .src_port == -1 then "-" else .src_port end),
      dst_host: (if .dst_host == "" then "-" else .dst_host end),
      dst_port: (if .dst_port == "" or .dst_port == -1 then "-" else .dst_port end),
      node_id: (if .node_id == "" then "-" else .node_id end),
      logdata: (if .logdata == "" then "-" else .logdata end)
    }
  )
| .[]
| "\(.local_time_adjusted | @html)\t\(.logtype | @html)\t\(.proto | @html)\t\(.src_host | @html)\t\(.src_port | @html)\t\(.dst_host | @html)\t\(.dst_port | @html)\t\(.node_id | @html)\t\(.logdata | @html)\t"
)' <<<"${msg}")

  output="
<!DOCTYPE html>
<html lang='es'>
<head>
  <style>
  table, th, td {
    border : 1px solid black;
    border-collapse : collapse;
    padding : 0.2rem;
    text-align: left;
  }
  </style>
  <title>Log</title>
</head>
<body>
<table> <tr> <th>Fecha</th>    <th>Tipo</th>    <th>Protocolo</th>    <th>Ip Origen</th>    <th>Puerto Origen</th>    <th>Ip Destino</th>    <th>Puerto Destino</th>    <th>Dispositivo Atacado</th>    <th>Datos</th> </tr>
${jsonParsedLineTable}
</table>
</body>
</html>"

  if [[ "$dangerLevel" -eq 0 ]]; then
    dangerMsg="Baja Importancia"
    targetMail="${reportOpenCanaryLowDangerTo}"
  else
    dangerMsg="Importante!"
    targetMail="${reportOpenCanaryDangerTo}"
  fi
  #  echo "DANGER LEVEL = ${dangerLevel}"
  #  echo "Original:"
  #  echo "${msg}"
  #  echo "Parsed:"
  #  echo "${columns}${jsonParsedLineTable}"
  echo "Email => Sending..."
  echo -e "${output}" | sudo mutt -e "set content_type=text/html" -s "Honeypot: ${dangerMsg}" -- "${targetMail}"
  echo "Email => SENT!"
}

function listenerMailer() {
  counterDanger=0
  counterLow=0
  msgDanger="["
  msgLow="["
  echo "Listener Mailer => waiting new line..."
  while read -r line; do
    if [ "$line" = "COMMIT!;" ]; then
      echo "Listener Mailer: COMMIT => arrived"
      if [[ $counterDanger -gt 0 ]]; then
        msgDanger="${msgDanger::-1}]"
        # FORK function and continue
        sendMail "${msgDanger}" "1" &
        msgDanger="["
        counterDanger=0
        #    else
        #      echo "ignoring danger commit"
      fi
      if [[ $counterLow -gt 0 ]]; then
        msgLow="${msgLow::-1}]"
        # FORK function and continue
        sendMail "${msgLow}" "0" &
        msgLow="["
        counterLow=0
        #    else
        #      echo "ignoring low commit"
      fi
    else
      echo "Listener Mailer: MSG => ${line}"
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
    fi
    echo "Listener Mailer => waiting new line..."
  done < <(nc -k -l 127.0.0.1 ${OPEN_CANARY_MAILER_PORT})
}

listenerMailer &

function openCanaryListener() {
  echo "OpenCanary Listener => waiting new line..."
  while read -r line; do
    echo -e "${line}" | nc -N -q 0 127.0.0.1 ${OPEN_CANARY_MAILER_PORT}
    echo "OpenCanary Listener => waiting new line..."
  done < <(nc -k -l 127.0.0.1 ${OPEN_CANARY_LISTEN_PORT})
}

openCanaryListener &

wait

echo "main thread finished"

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
  ["7001"]="HTTP PROXY LOGIN ATTEMPT"
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

PortGRE="(protocolo IP 47) Enrutamiento y acceso remoto"
PortESP="IPSec ESP (protocolo IP 50) Enrutamiento y acceso remoto"
PortAH="IPSec AH (protocolo IP 51) Enrutamiento y acceso remoto"
PortTCP=(
  ["1"]="Multiplexor TCP"
  ["5"]="Entrada de trabajo remota"
  ["7"]="Protocolo Echo (Eco) Responde con eco a llamadas remotas"
  ["9"]="Protocolo Discard, elimina cualquier dato que recibe, sirve para la evaluación de conexiones"
  ["11"]="Servicio del sistema para listar los puertos conectados"
  ["13"]="Protocolo Daytime, envía la fecha y hora actuales"
  ["17"]="Quote of the Day, envía la cita del día"
  ["18"]="Protocolo de envío de mensajes"
  ["19"]="Protocolo Chargen o Generador de caracteres, envía flujos infinitos de caracteres"
  ["20"]="FTPS File Transfer Protocol (Protocolo de Transferencia de Ficheros) - datos"
  ["21"]="FTP File Transfer Protocol (Protocolo de Transferencia de Ficheros) - control"
  ["22"]="SSH, scp, SFTP"
  ["23"]="Telnet manejo remoto de equipo, inseguro"
  ["25"]="SMTP Simple Mail Transfer Protocol (Protocolo Simple de Transferencia de Correo)"
  ["37"]="Time Protocol. Sincroniza hora y fecha"
  ["39"]="Protocolo de ubicación de recursos"
  ["42"]="Servicio de nombres de Internet"
  ["43"]="Servicio de directorio WHOIS"
  ["49"]="Terminal Access Controller Access Control System para el acceso y autenticación basado en TCP/IP"
  ["50"]="Protocolo de verificación de correo remoto"
  ["53"]="DNS Domain Name System (Sistema de Nombres de Dominio), por ejemplo BIND"
  ["63"]="Servicios extendidos de WHOIS (WHOIS++)"
  ["66"]="Software de red que permite acceso remoto entre los programas y la base de datos Oracle."
  ["70"]="Gopher"
  ["79"]="Finger"
  ["80"]="HTTP HyperText Transfer Protocol (Protocolo de Transferencia de HiperTexto) (WWW)"
  ["88"]="Kerberos Agente de autenticación"
  ["95"]="Extensión del protocolo Telnet"
  ["101"]="Servicios de nombres de host en máquinas SRI-NIC"
  ["107"]="Telnet remoto"
  ["109"]="POP2 Post Office Protocol (E-mail)"
  ["110"]="POP3 Post Office Protocol (E-mail)"
  ["111"]="sunrpc"
  ["113"]="ident (auth) antiguo sistema de identificación"
  ["115"]="SFTP (Simple FTP) Protocolo de transferencia de archivos simple"
  ["117"]="Servicios de rutas de Unix-to-Unix Copy Protocol (UUCP)"
  ["119"]="NNTP usado en los grupos de noticias de usenet"
  ["135"]="epmap"
  ["143"]="IMAP4 Internet Message Access Protocol (E-mail)"
  ["139"]="NetBIOS Servicio de sesiones"
  ["174"]="Cola de transporte de correos electrónicon MAILQ"
  ["177"]="XDMCP Protocolo de gestión de displays en X11"
  ["178"]="Servidor de ventanas NeXTStep"
  ["179"]="Border Gateway Protocol"
  ["194"]="Internet Relay Chat"
  ["199"]="SNMP UNIX Multiplexer"
  ["201"]="Enrutamiento AppleTalk"
  ["202"]="Enlace de nembres AppleTalk"
  ["204"]="Echo AppleTalk"
  ["206"]="Zona de información AppleTalk"
  ["209"]="Protocolo de transferencia rápida de correo (QMTP)"
  ["210"]="Base de datos NISO Z39.50"
  ["213"]="El protocolo de intercambio de paquetes entre redes (IPX)"
  ["220"]="IMAP versión 3"
  ["245"]="Servicio LINK / 3-DNS iQuery"
  ["347"]="Servicio de administración de cintas y archivos FATMEN"
  ["363"]="Túnel RSVP"
  ["369"]="Portmapper del sistema de archivos Coda"
  ["370"]="Servicios de autenticación del sistema de archivos Coda"
  ["372"]="UNIX LISTSERV"
  ["389"]="LDAP Protocolo de acceso ligero a Directorios"
  ["427"]="Protocolo de ubicación de servicios (SLP)"
  ["434"]="Agente móvil del Protocolo Internet"
  ["435"]="Gestor móvil del Protocolo Internet"
  ["443"]="HTTPS/SSL usado para la transferencia segura de páginas web"
  ["444"]="Protocolo simple de Network Pagging"
  ["445"]="Microsoft-DS (Active Directory, compartición en Windows, gusano Sasser, Agobot) o también es usado por Microsoft-DS compartición de ficheros"
  ["465"]="SMTP Sobre SSL. Utilizado para el envío de correo electrónico (E-mail)"
  ["512"]="exec"
  ["513"]="Rlogin"
  ["515"]="usado para la impresión en windows"
  ["587"]="SMTP Sobre TLS"
  ["591"]="FileMaker 6.0 (alternativa para HTTP, ver puerto 80)"
  ["631"]="CUPS sistema de impresión de Unix"
  ["666"]="identificación de Doom para jugar sobre TCP"
  ["690"]="VATP (Velneo Application Transfer Protocol) Protocolo de comunicaciones de Velneo"
  ["993"]="IMAP4 sobre SSL (E-mail)"
  ["995"]="POP3 sobre SSL (E-mail)"
  ["1001"]="SOCKS Proxy"
  ["1337"]="suele usarse en máquinas comprometidas o infectadas"
  ["1352"]="IBM Lotus Notes/Domino RCP"
  ["1433"]="Microsoft-SQL-Server"
  ["1434"]="Microsoft-SQL-Monitor"
  ["1494"]="Citrix MetaFrame Cliente IC"
  ["1512"]="WINS Windows Internet Naming Service"
  ["1521"]="Oracle puerto de escucha por defecto"
  ["1723"]="Enrutamiento y Acceso Remoto para VPN con PPTP."
  ["1761"]="Novell Zenworks Remote Control utility"
  ["1812"]="RADIUS authentication protocol, radius"
  ["1813"]="RADIUS accounting protocol, radius-acct"
  ["1883"]="MQTT protocol"
  ["1863"]="MSN Messenger"
  ["1935"]="FMS Flash Media Server"
  ["2049"]="NFS Archivos del sistema de red"
  ["2082"]="cPanel puerto por defecto"
  ["2083"]="CPanel puerto por defecto sobre SSL"
  ["2086"]="Web Host Manager puerto por defecto"
  ["3030"]="NetPanzer"
  ["3074"]="Xbox Live"
  ["3128"]="HTTP usado por web caches y por defecto en Squid cache | NDL-AAS"
  ["3306"]="MySQL sistema de gestión de bases de datos"
  ["3389"]="RDP (Remote Desktop Protocol) Terminal Server"
  ["3396"]="Novell agente de impresión NDPS"
  ["3690"]="Subversion (sistema de control de versiones)"
  ["4200"]="Angular, puerto por defecto"
  ["4443"]="AOL Instant Messenger (sistema de mensajería)"
  ["4662"]="eMule (aplicación de compartición de ficheros)"
  ["4899"]="RAdmin (Remote Administrator), herramienta de administración remota (normalmente troyanos)"
  ["5000"]="Universal plug-and-play"
  ["5001"]="Agente v6 Datadog"
  ["5190"]="AOL y AOL Instant Messenger"
  ["5222"]="Jabber/XMPP conexión de cliente"
  ["5223"]="Jabber/XMPP puerto por defecto para conexiones de cliente SSL"
  ["5269"]="Jabber/XMPP conexión de servidor"
  ["5432"]="PostgreSQL sistema de gestión de bases de datos"
  ["5517"]="Setiqueue proyecto SETI@Home"
  ["5631"]="PC-Anywhere protocolo de escritorio remoto"
  ["5400"]="VNC protocolo de escritorio remoto (usado sobre HTTP)"
  ["5500"]="VNC protocolo de escritorio remoto (usado sobre HTTP)"
  ["5600"]="VNC protocolo de escritorio remoto (usado sobre HTTP)"
  ["5700"]="VNC protocolo de escritorio remoto (usado sobre HTTP)"
  ["5800"]="VNC protocolo de escritorio remoto (usado sobre HTTP)"
  ["5900"]="VNC protocolo de escritorio remoto (conexión normal)"
  ["6000"]="X11 usado para X-windows"
  ["6129"]="Dameware Software conexión remota"
  ["6346"]="Gnutella compartición de ficheros (Limewire, etc.)"
  ["6667"]="IRC IRCU Internet Relay Chat"
  ["6881"]="BitTorrent puerto por defecto"
  ["6969"]="BitTorrent puerto de tracker"
  ["7100"]="Servidor de Fuentes X11"
  ["8000"]="iRDMI por lo general, usado erróneamente en sustitución de 8080. También utilizado en el servidor de streaming ShoutCast."
  ["8080"]="HTTP HTTP-ALT ver puerto 80. Tomcat lo usa como puerto por defecto."
  ["8118"]="privoxy"
  ["9009"]="Pichat peer-to-peer chat server"
  ["9898"]="Gusano Dabber (troyano/virus)"
  ["10000"]="Webmin (Administración remota web)"
  ["19226"]="Panda Security Puerto de comunicaciones de Panda Agent."
  ["12345"]="NetBus en:NetBus (troyano/virus)"
  ["25565"]="Minecraft Puerto por defecto usado por servidores del juego."
  ["31337"]="Back Orifice herramienta de administración remota (por lo general troyanos)"
  ["41121"]="Protocolo de transferencia utilizado por Pandora FMS."
  ["42000"]="Utilizado por Percona Monitoring Management para recoger métricas generales."
  ["42001"]="Utilizado por Percona Monitoring Management para recabar datos de desempeño."
  ["42002"]="Utilizado por Percona Monitoring Management para recabar métricas de MySQL."
  ["27017"]="Utilizado por Percona Monitoring Management para recabar métricas de MongoDB."
  ["42004"]="Utilizado por Percona Monitoring Management para recabar métricas de ProxySQL."
  ["45003"]="Calivent herramienta de administración remota SSH con análisis de paquetes."
)

PortUDP=(
  ["53"]="DNS Domain Name System (Sistema de Nombres de Dominio), por ejemplo BIND | FaceTime"
  ["66"]="Software de red que permite acceso remoto entre los programas y la base de datos Oracle."
  ["67"]="BOOTP BootStrap Protocol (servidor), también usado por DHCP"
  ["68"]="BOOTP BootStrap Protocol (cliente), también usado por DHCP"
  ["69"]="TFTP Trivial File Transfer Protocol (Protocolo Trivial de Transferencia de Ficheros)"
  ["123"]="NTP Protocolo de sincronización de tiempo"
  ["137"]="NetBIOS Servicio de nombres"
  ["138"]="NetBIOS Servicio de envío de datagramas"
  ["161"]="SNMP Simple Network Management Protocol"
  ["162"]="SNMP-trap"
  ["500"]="IPSec ISAKMP, Autoridad de Seguridad Local"
  ["514"]="syslog usado para logs del sistema"
  ["520"]="RIP Routing Information Protocol (Protocolo de Información de Enrutamiento)"
  ["521"]="RIP Routing Information Protocol IPv6 (Protocolo de Información de Enrutamiento Internet v6)"
  ["1194"]="OpenVPN Puerto por defecto en NAS Synology y QNAP"
  ["1701"]="Enrutamiento y Acceso Remoto para VPN con L2TP."
  ["1720"]="H.323"
  ["1812"]="RADIUS authentication protocol, radius"
  ["1813"]="RADIUS accounting protocol, radius-acct"
  ["2427"]="Cisco MGCP"
  ["3074"]="Xbox Live"
  ["3799"]="RADIUS CoA -change of authorization"
  ["3030"]="NetPanzer"
  ["4443"]="AOL Instant Messenger (sistema de mensajería)"
  ["4672"]="eMule (aplicación de compartición de ficheros)"
  ["5060"]="Session Initiation Protocol (SIP)"
  ["5632"]="PC-Anywhere protocolo de escritorio remoto"
  ["6112"]="Blizzard"
  ["6347"]="Gnutella"
  ["6348"]="Gnutella"
  ["6349"]="Gnutella"
  ["6350"]="Gnutella"
  ["6355"]="Gnutella"
  ["7100"]="Servidor de Fuentes X11"
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

function replacePort() {
  portVar="${1}"
  output="${2}"
  portNumber=$(grep -oP "${portVar}[\"\']\s*:\s*[\"\']*([+-]*\d+)[\"\']*" <<<"${output}")
  portNumber=$(grep -oP "[+-]*\d+" <<<"${portNumber}")

  portDesc="-"

  if [[ "$output" == *"\"PROTO\": \"TCP\""* ]]; then
    if [[ "$portNumber" == "-1" ]]; then
      portDesc="-"
    else
      portDesc=${PortTCP[${portNumber}]}
      if [ -z "${portDesc}" ]; then
        portDesc="-"
      fi
    fi
  fi

  if [[ "$output" == *"\"PROTO\": \"UDP\""* ]]; then
    if [[ "$portNumber" == "-1" ]]; then
      portDesc="-"
    else
      portDesc=${PortUDP[${portNumber}]}
      if [ -z "${portDesc}" ]; then
        portDesc="-"
      fi
    fi
  fi

  output=$(sed -e "s/\([\"\']\)${portVar}[\"\']\\s*:\\s*[\"\']*${portNumber}[\"\']*/\1${portVar}\1: ${portNumber}, \1${portVar}_desc\1: \1${portDesc}\1/g" <<<"${output}")

  echo -e "${output}"
}

function replaceValues() {
  output="${1}"
  for i in "${!LogTypes[@]}"; do
    # shellcheck disable=SC2001
    output=$(sed -e "s/\([\"\']\)logtype[\"\']\\s*:\\s*${i}/\1logtype\1: \1${LogTypes[${i}]}\1/g" <<<"${output}")
  done

  final=""

  while IFS= read -r line; do
    final+=$(replacePort "dst_port" "${line}")
  done <<<"${output}"

  echo -e "${final}"
}

function computeLogStats() {
  if [ -f "/var/tmp/opencanary.log" ]; then

    input="["
    while IFS= read -r line; do
      input+="${line},"
    done <"/var/tmp/opencanary.log"
    input="${input::-1}]"

    parsed=$(jq -r '(
  map(
      {
        local_time_adjusted,
        logtype: (if .logtype == "" then "-" else .logtype end),
        proto: (if .logdata.PROTO == "" or .logdata.PROTO == null or .logdata.PROTO == "null" then "-" else .logdata.PROTO end),
        src_host: (if .src_host == "" then "-" else .src_host end),
        src_port: (if .src_port == "" or .src_port == -1 then "-" else .src_port end),
        dst_host: (if .dst_host == "" then "-" else .dst_host end),
        dst_port: (if .dst_port == "" or .dst_port == -1 then "-" else .dst_port end),
        dst_port_desc: (if .dst_port_desc == "" then "-" else .dst_port_desc end),
        node_id: (if .node_id == "" then "-" else .node_id end),
        logdata: (if .logdata == "" then "-" else .logdata end)
      }
    )
  | .[]
  | "\(.local_time_adjusted)~\(.logtype)~\(.proto)~\(.src_host)~\(.src_port)~\(.dst_host)~\(.dst_port)~\(.dst_port_desc)~\(.node_id)~\(.logdata)"
  )' <<<"${input}")

    declare -A sourceIP

    while IFS= read -r line; do
      #  array=(${line//~/ })
      #  IFS='|' read -r local_time_adjusted logtype proto <<< "${line}"
      #  output+="${local_time_adjusted},${proto},
      #"

      while IFS='~' read -r local_time_adjusted logtype proto src_host src_port dst_host dst_port dst_port_desc node_id logdata; do
        if [[ ! -v "sourceIP['${src_host}']" ]]; then
          if [ "${logtype}" -ge 2000 ]; then
            sourceIP["${src_host}"]=0
          fi
        else
          sourceIP["${src_host}"]=$((sourceIP["${src_host}"] + 1))
        fi

      done <<<"${line}"

    done <<<"${parsed}"

    output=$(for k in "${!sourceIP[@]}"; do
      echo $k ' ' ${sourceIP["${k}"]}
    done |
      sort -rn -k2)

    output=$(echo -e "Origen Problemas\n${output}" | column -t)
    echo -e "${output}"
  else
    echo ""
  fi
}

function sendMail() {
  #  msg="${1}"
  echo "Email => Formatting ..."
  echo "${1}"
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
      dst_port_desc: (if .dst_port_desc == "" then "-" else .dst_port_desc end),
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
  <td>\(.dst_port_desc | @html)</td>
  <td>\(.node_id | @html)</td>
  <td>\(.logdata | @html)</td>
</tr>"
)' <<<"${msg}")

stats=$(computeLogStats)

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
<table> <tr> <th>Fecha</th>  <th>Tipo</th>  <th>Protocolo</th>  <th>Host Origen</th>    <th>Puerto Origen</th>    <th>Host Destino</th>    <th>Puerto Destino</th>   <th>Posible Objetivo</th>   <th>Dispositivo Atacado</th>    <th>Datos</th> </tr>
${jsonParsedLineTable}
<br>
<hr>
<p>Estadística actual de atacantes</p>
<pre>
  <code>
${stats}
  </code>
</pre>
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
        msgDanger+="${line}
"
        counterDanger=$((counterDanger + 1))
        if [[ "$counterDanger" -eq ${MSG_UNTIL_SEND_MAIL} ]]; then
          msgDanger+="]"
          #          echo "${msgDanger}"
          # FORK function and continue
          sendMail "${msgDanger}" "1" &
          msgDanger="["
          counterDanger=0
        else
          msgDanger+=","
        fi
      else
        # ======= append to low mail =========
        msgLow+="${line}
"
        counterLow=$((counterLow + 1))
        if [[ "$counterLow" -eq ${MSG_UNTIL_SEND_MAIL} ]]; then
          msgLow+="]"
          #          echo "${msgLow}"
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

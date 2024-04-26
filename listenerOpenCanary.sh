#!/usr/bin/env bash
#
# Copyright (c) 2023. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
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

declare -A KnownUsers
KnownUsers=(
  ["190.11.141.242"]="Router ITT"
  ["190.11.141.248"]="developer.cevt.ar"
  ["190.11.141.243"]="mail.cevt.ar"
  ["190.11.141.244"]="web.cevt.ar"
  ["190.11.141.245"]="net.cevt.ar"
  ["190.11.141.246"]="itt.cevt.ar"
  ["190.11.141.249"]="Wifi 7mo"
  ["181.98.22.146"]="Router ITT"
  ["181.98.22.147"]="developer.cevt.ar"
  ["181.98.22.148"]="mail.cevt.ar"
  ["181.98.22.149"]="web.cevt.ar"
  ["181.98.22.150"]="net.cevt.ar"
  ["181.98.22.151"]="itt.cevt.ar"
  ["181.98.22.153"]="Wifi 7mo"
  ["192.168.0.141"]="ADMIN - -1 - Mantenimiento - Damian Miscoff - PC - CEVT-000214 - CPU-204"
  ["192.168.1.141"]="ADMIN - -1 - Mantenimiento - Damian Miscoff - PC - CEVT-000214 - CPU-204"
  ["192.168.1.151"]="ADMIN - 0 - Atencion a Usuarios - Candida Medina - IMPRESORA - HP M404 - CEVT-000047"
  ["192.168.1.65"]="ADMIN - 0 - Atencion a Usuarios - Candida Medina - PC - CEVT-000589 - CPU-287"
  ["192.168.0.65"]="ADMIN - 0 - Atencion a Usuarios - Candida Medina - PC - CEVT-000589 - CPU-287"
  ["192.168.0.60"]="ADMIN - 0 - Atencion a Usuarios - Maria Lucia Di Miscia - PC - CEVT-000661 - CPU-293"
  ["192.168.1.60"]="ADMIN - 0 - Atencion a Usuarios - Maria Lucia Di Miscia - PC - CEVT-000661 - CPU-293"
  ["192.168.1.144"]="ADMIN - 0 - Atencion a Usuarios - PASANTE - PC - CEVT-000341 - CPU-270"
  ["192.168.0.144"]="ADMIN - 0 - Atencion a Usuarios - PASANTE - PC - CEVT-000341 - CPU-270"
  ["192.168.1.111"]="ADMIN - 0 - Atencion a Usuarios - Pasillo - IMPRESORA - Brother DCP-8150 - CEVT-000044"
  ["192.168.1.146"]="ADMIN - 0 - Atencion a Usuarios - Victoria Martinez - IMPRESORA - HP M404 - CEVT-000046"
  ["192.168.1.71"]="ADMIN - 0 - Atencion a Usuarios - Victoria Martinez - PC - CEVT-000655 - CPU-292"
  ["192.168.0.71"]="ADMIN - 0 - Atencion a Usuarios - Victoria Martinez - PC - CEVT-000655 - CPU-292"
  ["192.168.1.30"]="ADMIN - 0 - Caja 1 - Agustina Bianco - PC - CEVT-000382 - CPU-083"
  ["192.168.1.92"]="ADMIN - 0 - Caja 2 - VACANTE - PC - CEVT-000388 - CPU-211"
  ["192.168.1.91"]="ADMIN - 0 - Caja 3 - Mariano Carpanetti - PC - CEVT-000925 - CPU-210"
  ["192.168.0.91"]="ADMIN - 0 - Caja 3 - Mariano Carpanetti - PC - CEVT-000925 - CPU-210"
  ["192.168.1.93"]="ADMIN - 0 - Caja 4  - Sonia Tisera - PC - CEVT-000400 - CPU-082"
  ["192.168.0.93"]="ADMIN - 0 - Caja 4  - Sonia Tisera - PC - CEVT-000400 - CPU-082"
  ["192.168.1.90"]="ADMIN - 0 - Caja 5 - Antonella Ronco - PC - CEVT-000101 - CPU-225"
  ["192.168.0.90"]="ADMIN - 0 - Caja 5 - Antonella Ronco - PC - CEVT-000101 - CPU-225"
  ["192.168.1.97"]="ADMIN - 0 - Cajas - Pasillo - IMPRESORA - HP 402 - CEVT-000043"
  ["192.168.1.192"]="ADMIN - 0 - Cajas - TURNOS - Pantalla"
  ["192.168.1.193"]="ADMIN - 0 - Cajas - TURNOS - Tickets"
  ["192.168.0.193"]="ADMIN - 0 - Cajas - TURNOS - Tickets"
  ["192.168.1.39"]="ADMIN - 0 - Deudores - Leandro Toselli - PC - CEVT-000595 - CPU-286"
  ["192.168.0.39"]="ADMIN - 0 - Deudores - Leandro Toselli - PC - CEVT-000595 - CPU-286"
  ["192.168.1.149"]="ADMIN - 0 - Deudores - Sebastian Puigrredon - IMPRESORA - HP M401 - CEVT-000050"
  ["192.168.1.64"]="ADMIN - 0 - Deudores - Sebastian Puigrredon - PC - CEVT-000329 - CPU-216"
  ["192.168.0.64"]="ADMIN - 0 - Deudores - Sebastian Puigrredon - PC - CEVT-000329 - CPU-216"
  ["192.168.1.109"]="ADMIN - 0 - Deudores - Sergio Di Martino - IMPRESORA - HP M401 - CEVT-000049"
  ["192.168.1.72"]="ADMIN - 0 - Deudores - Sergio Di Martino - PC - CEVT-000335	- CPU-217"
  ["192.168.0.72"]="ADMIN - 0 - Deudores - Sergio Di Martino - PC - CEVT-000335	- CPU-217"
  ["192.168.1.70"]="ADMIN - 0 - Recepcion - Cristian Carpanetti - PC - CEVT-000348 - CPU-227"
  ["192.168.0.70"]="ADMIN - 0 - Recepcion - Cristian Carpanetti - PC - CEVT-000348 - CPU-227"
  ["192.168.1.145"]="ADMIN - 0 - Recepcion - Silvana Gimenez - IMPRESORA - HP M404 - CEVT-000045"
  ["192.168.1.73"]="ADMIN - 0 - Recepcion - Silvana Gimenez - PC	- CEVT-000375	- CPU-259"
  ["192.168.0.73"]="ADMIN - 0 - Recepcion - Silvana Gimenez - PC	- CEVT-000375	- CPU-259"
  ["192.168.0.250"]="ADMIN - 1 - Sala de reuniones - CAPACITACION - PC - CEVT-000441 - CPU-236"
  ["192.168.1.250"]="ADMIN - 1 - Sala de reuniones - CAPACITACION - PC - CEVT-000441 - CPU-236"
  ["192.168.1.75"]="ADMIN - 1 - Secretaria del Consejo - Juan Carlos Rodriguez - PC - CEVT-000427 - CPU-255"
  ["192.168.0.75"]="ADMIN - 1 - Secretaria del Consejo - Juan Carlos Rodriguez - PC - CEVT-000427 - CPU-255"
  ["192.168.1.45"]="ADMIN - 2 - Gerencia Administrativa - Dario Moreira - PC - CEVT-000264 - CPU-208"
  ["192.168.0.45"]="ADMIN - 2 - Gerencia Administrativa - Dario Moreira - PC - CEVT-000264 - CPU-208"
  ["192.168.1.37"]="ADMIN - 2 - REC y PAGOS - Adrian Llopiz - PC - CEVT-000877 - CPU-283"
  ["192.168.0.37"]="ADMIN - 2 - REC y PAGOS - Adrian Llopiz - PC - CEVT-000877 - CPU-283"
  ["192.168.1.40"]="ADMIN - 2 - REC y PAGOS - Ariel Viano - PC - CEVT-000699 - CPU-297"
  ["192.168.0.40"]="ADMIN - 2 - REC y PAGOS - Ariel Viano - PC - CEVT-000699 - CPU-297"
  ["192.168.1.113"]="ADMIN - 2 - REC y PAGOS - Ariel/Silvana - IMPRESORA - HP M401 - CEVT-000052"
  ["192.168.1.132"]="ADMIN - 2 - REC y PAGOS - Federico Bazetti - IMPRESORA - HP M404 - CEVT-000895"
  ["192.168.1.143"]="ADMIN - 2 - REC y PAGOS - Federico Bazzetti - PC - CEVT-000207 - CPU-220"
  ["192.168.0.143"]="ADMIN - 2 - REC y PAGOS - Federico Bazzetti - PC - CEVT-000207 - CPU-220"
  ["192.168.1.28"]="ADMIN - 2 - REC y PAGOS - Federico Bazzetti - PC - CEVT-000687 - CPU-295"
  ["192.168.0.28"]="ADMIN - 2 - REC y PAGOS - Federico Bazzetti - PC - CEVT-000687 - CPU-295"
  ["192.168.1.25"]="ADMIN - 2 - REC y PAGOS - Roman Rossi - PC - CEVT-000229 - CPU-231"
  ["192.168.0.25"]="ADMIN - 2 - REC y PAGOS - Roman Rossi - PC - CEVT-000229 - CPU-231"
  ["192.168.1.102"]="ADMIN - 2 - REC y PAGOS - Roman/Valeria - IMPRESORA - HP M401 - CEVT-000030"
  ["192.168.1.42"]="ADMIN - 2 - REC y PAGOS - Rosana Buljubasich - PC - CEVT-000190 - CPU-207"
  ["192.168.0.42"]="ADMIN - 2 - REC y PAGOS - Rosana Buljubasich - PC - CEVT-000190 - CPU-207"
  ["192.168.1.221"]="ADMIN - 2 - REC y PAGOS - Silvana Foresi - PC - CEVT-000368 - CPU-212"
  ["192.168.0.221"]="ADMIN - 2 - REC y PAGOS - Silvana Foresi - PC - CEVT-000368 - CPU-212"
  ["192.168.1.27"]="ADMIN - 2 - REC y PAGOS - Valeria Airasca - PC	- CEVT-000693	- CPU-296"
  ["192.168.0.27"]="ADMIN - 2 - REC y PAGOS - Valeria Airasca - PC	- CEVT-000693	- CPU-296"
  ["192.168.1.116"]="ADMIN - 2 - Segundo piso - Pasillo - IMPRESORA - Brother DCP-L5600 - CEVT-000272"
  ["192.168.1.110"]="ADMIN - 2 - Usuarios - Alejandra Correa - IMPRESORA - HP P4515 - CEVT-000009"
  ["192.168.1.68"]="ADMIN - 2 - Usuarios - Alejandra Correa - PC - CEVT-000250 - CPU-203"
  ["192.168.0.68"]="ADMIN - 2 - Usuarios - Alejandra Correa - PC - CEVT-000250 - CPU-203"
  ["192.168.1.29"]="ADMIN - 2 - Usuarios - Alejandra Correa - PC - CEVT-000575 - CPU-289"
  ["192.168.0.29"]="ADMIN - 2 - Usuarios - Alejandra Correa - PC - CEVT-000575 - CPU-289"
  ["192.168.0.23"]="ADMIN - 2 - Usuarios - Brenda Roldan - PC - CEVT-000572 - CPU-288"
  ["192.168.1.23"]="ADMIN - 2 - Usuarios - Brenda Roldan - PC - CEVT-000572 - CPU-288"
  ["192.168.0.53"]="ADMIN - 2 - Usuarios - Cecilia Nievas - PC - CEVT-000789 - CPU-303"
  ["192.168.1.53"]="ADMIN - 2 - Usuarios - Cecilia Nievas - PC - CEVT-000789 - CPU-303"
  ["192.168.1.148"]="ADMIN - 2 - Usuarios - Daniel Ureta - IMPRESORA - HP M404 - CEVT-000036"
  ["192.168.1.66"]="ADMIN - 2 - Usuarios - Daniel Ureta - PC - CEVT-000273 - CPU-262"
  ["192.168.0.66"]="ADMIN - 2 - Usuarios - Daniel Ureta - PC - CEVT-000273 - CPU-262"
  ["192.168.1.103"]="ADMIN - 2 - Usuarios - Facturacion - IMPRESORA - Lexmark MS812 - CEVT-000038	(REPUESTO)"
  ["192.168.1.135"]="ADMIN - 2 - Usuarios - Facturacion - IMPRESORA - Ricoh MP7502 - CEVT-000896"
  ["192.168.1.147"]="ADMIN - 2 - Usuarios - Laura Viano - IMPRESORA - HP M404 - CEVT-000035"
  ["192.168.1.62"]="ADMIN - 2 - Usuarios - Laura Viano - PC - CEVT-000280 - CPU-234"
  ["192.168.0.62"]="ADMIN - 2 - Usuarios - Laura Viano - PC - CEVT-000280 - CPU-234"
  ["192.168.1.158"]="ADMIN - 2 - Usuarios - Paula Viano - IMPRESORA - HP M404 - CEVT-000739"
  ["192.168.1.63"]="ADMIN - 2 - Usuarios - Paula Viano - PC - CEVT-000607 - CPU-290"
  ["192.168.0.63"]="ADMIN - 2 - Usuarios - Paula Viano - PC - CEVT-000607 - CPU-290"
  ["192.168.1.32"]="ADMIN - 2 - Usuarios - Vanina Tome - PC - CEVT-000649 - CPU-291"
  ["192.168.0.32"]="ADMIN - 2 - Usuarios - Vanina Tome - PC - CEVT-000649 - CPU-291"
  ["192.168.1.35"]="ADMIN - 3 - Compras - Walter Ruiz - PC - CEVT-000175 - CPU-232"
  ["192.168.0.35"]="ADMIN - 3 - Compras - Walter Ruiz - PC - CEVT-000175 - CPU-232"
  ["192.168.1.31"]="ADMIN - 3 - Datacenter - Carlos Durand - PC - CEVT-000985 - CPU-088"
  ["192.168.0.31"]="ADMIN - 3 - Datacenter - Carlos Durand - PC - CEVT-000985 - CPU-088"
  ["192.168.1.44"]="ADMIN - 3 - Datacenter - Carlos Durand - PC - CPU-268"
  ["192.168.0.44"]="ADMIN - 3 - Datacenter - Carlos Durand - PC - CPU-268"
  ["192.168.1.16"]="ADMIN - 3 - Datacenter - FREENAS .14 y .15 - Servidor - CEVT-000499"
  ["192.168.1.154"]="ADMIN - 3 - Datacenter - Facturas Online - PC - CEVT-000523 - CPU-206"
  ["192.168.0.154"]="ADMIN - 3 - Datacenter - Facturas Online - PC - CEVT-000523 - CPU-206"
  ["192.168.0.120"]="ADMIN - 3 - Datacenter - IPDIFF - PC - CEVT-000322 - CPU-218"
  ["192.168.1.120"]="ADMIN - 3 - Datacenter - IPDIFF - PC - CEVT-000322 - CPU-218"
  ["192.168.200.120"]="ADMIN - 3 - Datacenter - IPDIFF - PC - CEVT-000322 - CPU-218"
  ["192.168.1.231"]="ADMIN - 3 - Datacenter - Monitoreo - PC - CEVT-000355 - CPU-228"
  ["192.168.0.231"]="ADMIN - 3 - Datacenter - Monitoreo - PC - CEVT-000355 - CPU-228"
  ["192.168.1.134"]="ADMIN - 3 - Datacenter - Procesamiento - IMPRESORA - HP P4515 - CEVT-000037 (REPUESTO)"
  ["192.168.0.20"]="ADMIN - 3 - Datacenter - Q-NAP - NAS - CEVT-000530 - CPU-267"
  ["192.168.1.20"]="ADMIN - 3 - Datacenter - Q-NAP - NAS - CEVT-000530 - CPU-267"
  ["192.168.0.5"]="ADMIN - 3 - Datacenter - Servidor - CEVT-000495"
  ["192.168.1.5"]="ADMIN - 3 - Datacenter - Servidor - CEVT-000495"
  ["192.168.0.17"]="ADMIN - 3 - Datacenter - Turnos Caja - Servidor - CEVT-000986 - CPU-229"
  ["192.168.1.17"]="ADMIN - 3 - Datacenter - Turnos Caja - Servidor - CEVT-000986 - CPU-229"
  ["192.168.1.69"]="ADMIN - 3 - Gerencia - Alberto Corradini - PC - CEVT-000416 - CPU-251"
  ["192.168.0.69"]="ADMIN - 3 - Gerencia - Alberto Corradini - PC - CEVT-000416 - CPU-251"
  ["192.168.0.138"]="ADMIN - 3 - Personal - Angelo Rossi - PC - CEVT-000161 - CPU-276"
  ["192.168.1.138"]="ADMIN - 3 - Personal - Angelo Rossi - PC - CEVT-000161 - CPU-276"
  ["192.168.1.119"]="ADMIN - 3 - Personal - Daniel Bonfanti - IMPRESORA - HP M402 - CEVT-000016"
  ["192.168.0.137"]="ADMIN - 3 - Personal - Daniel Bonfanti - PC - CEVT-000600 - CPU-282"
  ["192.168.1.137"]="ADMIN - 3 - Personal - Daniel Bonfanti - PC - CEVT-000600 - CPU-282"
  ["192.168.1.94"]="ADMIN - 3 - Personal - Luisina Ali - IMPRESORA - HP M402 - CEVT-000014"
  ["192.168.1.61"]="ADMIN - 3 - Personal - Luisina Ali - PC - CEVT-000154 - CPU-258"
  ["192.168.0.61"]="ADMIN - 3 - Personal - Luisina Ali - PC - CEVT-000154 - CPU-258"
  ["192.168.1.133"]="ADMIN - 3 - Procesamiento - Dardo Mobilia - IMPRESORA - HP M404 - CEVT-000962"
  ["192.168.1.46"]="ADMIN - 3 - Procesamiento - Dardo Mobilia - PC - CEVT-000088 - CPU-213"
  ["192.168.0.46"]="ADMIN - 3 - Procesamiento - Dardo Mobilia - PC - CEVT-000088 - CPU-213"
  ["192.168.1.43"]="ADMIN - 3 - Procesamiento - Dardo Mobilia - PC - CEVT-000095 - CPU-084"
  ["192.168.0.43"]="ADMIN - 3 - Procesamiento - Dardo Mobilia - PC - CEVT-000095 - CPU-084"
  ["192.168.1.106"]="ADMIN - 3 - Procesamiento - Ex Raul Sanchez - IMPRESORA - HP M401 - CEVT-000006"
  ["192.168.1.26"]="ADMIN - 3 - Procesamiento - Ex Raul Sanchez - PC - CEVT-000080 - CPU-091"
  ["192.168.0.22"]="ADMIN - 3 - Procesamiento - Ex Raul Sanchez - PC - CEVT-000668 - CPU-294"
  ["192.168.1.22"]="ADMIN - 3 - Procesamiento - Ex Raul Sanchez - PC - CEVT-000668 - CPU-294"
  ["192.168.1.153"]="ADMIN - 3 - Procesamiento - Federico Ruiz - IMPRESORA - HP M401 - CEVT-000011"
  ["192.168.0.157"]="ADMIN - 3 - Procesamiento - Federico Ruiz - PC - CEVT-000108 - CPU-275"
  ["192.168.1.157"]="ADMIN - 3 - Procesamiento - Federico Ruiz - PC - CEVT-000108 - CPU-275"
  ["192.168.1.105"]="ADMIN - 3 - Procesamiento - Martin Vieguer - IMPRESORA - HP M203 - CEVT-000008"
  ["192.168.1.34"]="ADMIN - 3 - Procesamiento - Martin Vieguer - PC - CEVT-000889 - CPU-285"
  ["192.168.0.34"]="ADMIN - 3 - Procesamiento - Martin Vieguer - PC - CEVT-000889 - CPU-285"
  ["192.168.0.81"]="ADMIN - 3 - Secretaria Gerencia - Ana Dominguez - PC- CEVT-000447 - CPU-219"
  ["192.168.1.81"]="ADMIN - 3 - Secretaria Gerencia - Ana Dominguez - PC- CEVT-000447 - CPU-219"
  ["192.168.1.136"]="ADMIN - 3 - Secretaria de Gerencia - Ana Dominguez - IMPRESORA - HP P3015 - CEVT-000970"
  ["192.168.1.112"]="ADMIN - 3 - Tercer piso - Pasillo - IMPRESORA - Brother MCF-8950 - CEVT-000018"
  ["192.168.1.36"]="ADMIN - 7 - Contabilidad - Auditor Externo - PC - CEVT-000243 - CPU-201"
  ["192.168.0.36"]="ADMIN - 7 - Contabilidad - Auditor Externo - PC - CEVT-000243 - CPU-201"
  ["192.168.1.99"]="ADMIN - 7 - Contabilidad - Graciela Cozzi - IMPRESORA - HP M402 - CEVT-000034"
  ["192.168.1.38"]="ADMIN - 7 - Contabilidad - Graciela Cozzi - PC - CEVT-000558 - CPU-280"
  ["192.168.0.38"]="ADMIN - 7 - Contabilidad - Graciela Cozzi - PC - CEVT-000558 - CPU-280"
  ["192.168.1.107"]="ADMIN - 7 - Contabilidad - Pia Corradini - IMPRESORA - HP M402 - CEVT-000032"
  ["192.168.1.33"]="ADMIN - 7 - Contabilidad - Pia Corradini - PC - CEVT-000256 - CPU-279"
  ["192.168.0.33"]="ADMIN - 7 - Contabilidad - Pia Corradini - PC - CEVT-000256 - CPU-279"
  ["192.168.0.84"]="ADMIN - 7 - Sistemas IT - Cobranza Maggiolo - PC - CEVT-000169 - CPU-209"
  ["192.168.1.84"]="ADMIN - 7 - Sistemas IT - Cobranza Maggiolo - PC - CEVT-000169 - CPU-209"
  ["192.168.0.253"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - Honeypot"
  ["192.168.1.253"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - Honeypot"
  ["192.168.0.155"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - Notebook"
  ["192.168.1.155"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - Notebook"
  ["192.168.0.150"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - PC - CEVT-000748 - CPU-298"
  ["192.168.1.150"]="ADMIN - 7 - Sistemas IT - Franco Pellegrini - PC - CEVT-000748 - CPU-298"
  ["192.168.0.254"]="ADMIN - 7 - Sistemas IT - Instalacion y mantenimiento - PC"
  ["192.168.1.254"]="ADMIN - 7 - Sistemas IT - Instalacion y mantenimiento - PC"
  ["192.168.1.156"]="ADMIN - 7 - Sistemas IT - Martin Rossi - PC - CEVT-000783 - CPU-301"
  ["192.168.0.156"]="ADMIN - 7 - Sistemas IT - Martin Rossi - PC - CEVT-000783 - CPU-301"
  ["192.168.1.232"]="ADMIN - 7 - Sistemas IT - Monitoreo - PC - CEVT-000137 - CPU-226"
  ["192.168.0.232"]="ADMIN - 7 - Sistemas IT - Monitoreo - PC - CEVT-000137 - CPU-226"
  ["192.168.0.24"]="ADMIN - 7 - Sistemas IT - Omar Pellegini - PC - CEVT-000072 - CPU-271"
  ["192.168.1.24"]="ADMIN - 7 - Sistemas IT - Omar Pellegini - PC - CEVT-000072 - CPU-271"
  ["192.168.1.159"]="ADMIN - 7 - Sistemas-IT - Fotocopias - IMPRESORA - Brother DCP-L2540 - CEVT-000007"
  ["192.168.1.118"]="ADMIN - 7 - Sistemas-IT - Martin/Franco - IMPRESORA - HP M402 - CEVT-000010"
  ["192.168.1.77"]="ADMIN - 8 - Banda Ancha - Banda Ancha CMTS - PC - CPU-072"
  ["192.168.0.77"]="ADMIN - 8 - Banda Ancha - Banda Ancha CMTS - PC - CPU-072"
  ["192.168.0.142"]="ADMIN - 8 - Banda Ancha - Javier Gatti - PC - CEVT-000454 - CPU-260"
  ["192.168.1.142"]="ADMIN - 8 - Banda Ancha - Javier Gatti - PC - CEVT-000454 - CPU-260"
  ["192.168.1.78"]="ADMIN - 8 - Banda Ancha - Mauricio Gimenez - PC - CEVT-000460 - CPU-277"
  ["192.168.0.78"]="ADMIN - 8 - Banda Ancha - Mauricio Gimenez - PC - CEVT-000460 - CPU-277"
  ["192.168.0.140"]="ADMIN - 8 - Legales - Lucia Ledesma - PC - CEVT-000775 - CPU-300"
  ["192.168.1.140"]="ADMIN - 8 - Legales - Lucia Ledesma - PC - CEVT-000775 - CPU-300"
  ["192.168.0.139"]="ADMIN - 8 - Legales - Miguel Murtagh - PC - CEVT-000059 - CPU-269"
  ["192.168.1.139"]="ADMIN - 8 - Legales - Miguel Murtagh - PC - CEVT-000059 - CPU-269"
  ["192.168.0.217"]="ITS (GIS) - Mantenimiento y Desarollo - Mario Perillo"
  ["192.168.1.217"]="ITS (GIS) - Mantenimiento y Desarollo - Mario Perillo"
  ["192.168.1.86"]="PARQUE INDUSTRIAL - Fabrica de postes - Gonzalo Achondo - PC - CEVT-000954 - CPU-079"
  ["192.168.0.86"]="PARQUE INDUSTRIAL - Fabrica de postes - Gonzalo Achondo - PC - CEVT-000954 - CPU-079"
  ["192.168.1.47"]="PLANTA - Deposito - Fernando Ratto - PC - CEVT-000801 - CPU-202"
  ["192.168.0.47"]="PLANTA - Deposito - Fernando Ratto - PC - CEVT-000801 - CPU-202"
  ["192.168.0.41"]="PLANTA - Distribucion - Pablo Urdiales - Notebook - CEVT-000880"
  ["192.168.1.41"]="PLANTA - Distribucion - Pablo Urdiales - Notebook - CEVT-000880"
  ["192.168.0.58"]="PLANTA - Distribucion - Pablo Urdiales - PC - CEVT-000549 - CPU-247"
  ["192.168.1.58"]="PLANTA - Distribucion - Pablo Urdiales - PC - CEVT-000549 - CPU-247"
  ["192.168.1.18"]="PLANTA - Laboratorio - CAMARAS DE SEGURIDAD - DVR"
  ["192.168.0.88"]="PLANTA - Laboratorio - Javier Llopiz - PC - CEVT-000826 - CPU-250"
  ["192.168.1.88"]="PLANTA - Laboratorio - Javier Llopiz - PC - CEVT-000826 - CPU-250"
  ["192.168.1.12"]="PLANTA - Laboratorio - NAS BACKUP SERVER SISTEMAS - NAS"
  ["192.168.1.114"]="PLANTA - Laboratorio - Nestor Nieto - IMPRESORA - HP M402 - CEVT-000911"
  ["192.168.1.74"]="PLANTA - Laboratorio - Nestor Nieto - PC - CEVT-000806 - CPU-205"
  ["192.168.0.74"]="PLANTA - Laboratorio - Nestor Nieto - PC - CEVT-000806 - CPU-205"
  ["192.168.0.85"]="PLANTA - Luminarias - Guardafocos - PC - CEVT-000537 - CPU-272"
  ["192.168.1.85"]="PLANTA - Luminarias - Guardafocos - PC - CEVT-000537 - CPU-272"
  ["192.168.0.131"]="PLANTA - Mediciones - Luis Pozuelo - PC - CEVT-000882 - CPU-281"
  ["192.168.1.131"]="PLANTA - Mediciones - Luis Pozuelo - PC - CEVT-000882 - CPU-281"
  ["192.168.1.220"]="PLANTA - Mediciones - PASANTE - PC - CEVT-000288 - CPU-090"
  ["192.168.0.220"]="PLANTA - Mediciones - PASANTE - PC - CEVT-000288 - CPU-090"
  ["192.168.0.9"]="PLANTA - Oficina Tecnica - BACK-OT - Server"
  ["192.168.1.9"]="PLANTA - Oficina Tecnica - BACK-OT - Server"
  ["192.168.1.79"]="PLANTA - Oficina Tecnica - Cristian Marmiroli - PC - CEVT-000861 - CPU-274"
  ["192.168.0.79"]="PLANTA - Oficina Tecnica - Cristian Marmiroli - PC - CEVT-000861 - CPU-274"
  ["192.168.1.52"]="PLANTA - Oficina Tecnica - Fabian Arditti - PC - CEVT-000831 - CPU-252"
  ["192.168.0.52"]="PLANTA - Oficina Tecnica - Fabian Arditti - PC - CEVT-000831 - CPU-252"
  ["192.168.1.117"]="PLANTA - Oficina Tecnica - Fabian Arditti - PC - CPU-064"
  ["192.168.0.117"]="PLANTA - Oficina Tecnica - Fabian Arditti - PC - CPU-064"
  ["192.168.1.55"]="PLANTA - Oficina Tecnica - Federico Murtagh - PC - CEVT-000903 - CPU-221"
  ["192.168.0.55"]="PLANTA - Oficina Tecnica - Federico Murtagh - PC - CEVT-000903 - CPU-221"
  ["192.168.0.13"]="PLANTA - Oficina Tecnica - GIS - Server - CPU-230"
  ["192.168.1.13"]="PLANTA - Oficina Tecnica - GIS - Server - CPU-230"
  ["192.168.1.8"]="PLANTA - Oficina Tecnica - GIS PRIMARIO - Server - CPU-230"
  ["192.168.0.8"]="PLANTA - Oficina Tecnica - GIS PRIMARIO - Server - CPU-230"
  ["192.168.1.49"]="PLANTA - Oficina Tecnica - INFO-OT - Server - CEVT-000897 - CPU-085"
  ["192.168.0.49"]="PLANTA - Oficina Tecnica - INFO-OT - Server - CEVT-000897 - CPU-085"
  ["192.168.0.59"]="PLANTA - Oficina Tecnica - Martin Ureta - PC - CEVT-000821 - CPU-248"
  ["192.168.1.59"]="PLANTA - Oficina Tecnica - Martin Ureta - PC - CEVT-000821 - CPU-248"
  ["192.168.1.194"]="PLANTA - Oficina Tecnica - Mauricio Ronco - IMPRESORA - Brother DCP-820 - CEVT-000976"
  ["192.168.1.96"]="PLANTA - Oficina Tecnica - Mauricio Ronco - IMPRESORA - HP M402 - CEVT-000912"
  ["192.168.1.51"]="PLANTA - Oficina Tecnica - Mauricio Ronco - PC - CEVT-000816 - CPU-235"
  ["192.168.0.51"]="PLANTA - Oficina Tecnica - Mauricio Ronco - PC - CEVT-000816 - CPU-235"
  ["192.168.1.101"]="PLANTA - Oficina Tecnica - Notebook GP - NOTEBOOK - CEVT-000533 - CPU-284"
  ["192.168.0.101"]="PLANTA - Oficina Tecnica - Notebook GP - NOTEBOOK - CEVT-000533 - CPU-284"
  ["192.168.1.56"]="PLANTA - Oficina Tecnica - Sebastian Long - PC - CEVT-000856 - CPU-261"
  ["192.168.0.56"]="PLANTA - Oficina Tecnica - Sebastian Long - PC - CEVT-000856 - CPU-261"
  ["192.168.1.54"]="PLANTA - Oficina Tecnica - Sebastian Suarez (NO PRENDER) - PC - CPU-065"
  ["192.168.0.54"]="PLANTA - Oficina Tecnica - Sebastian Suarez (NO PRENDER) - PC - CPU-065"
  ["192.168.0.124"]="PLANTA - Oficina Tecnica - Sebastian Suarez - PC - CEVT-000846 - CPU-256"
  ["192.168.1.124"]="PLANTA - Oficina Tecnica - Sebastian Suarez - PC - CEVT-000846 - CPU-256"
  ["192.168.0.87"]="PLANTA - Oficina Tecnica - Sergio Demarchi - PC - CEVT-000811 - CPU-233"
  ["192.168.1.87"]="PLANTA - Oficina Tecnica - Sergio Demarchi - PC - CEVT-000811 - CPU-233"
  ["192.168.0.122"]="PLANTA - Reclamos - Henry Viera - PC - CEVT-000475 - CPU-246"
  ["192.168.1.122"]="PLANTA - Reclamos - Henry Viera - PC - CEVT-000475 - CPU-246"
  ["192.168.1.121"]="PLANTA - Reclamos - Tableristas - IMPRESORA - HP M501 - CEVT-000908"
  ["192.168.0.100"]="PLANTA - Reclamos - Tableristas - PC - CEVT-000872 - CPU-249"
  ["192.168.1.100"]="PLANTA - Reclamos - Tableristas - PC - CEVT-000872 - CPU-249"
  ["192.168.0.129"]="PLANTA - Redes TM - Cristian Martinez - PC - CEVT-000866 - CPU-278"
  ["192.168.1.129"]="PLANTA - Redes TM - Cristian Martinez - PC - CEVT-000866 - CPU-278"
  ["192.168.1.127"]="PLANTA - Redes TM - Sergio Pereyra - IMPRESORA - HP M501 - CEVT-000909"
  ["192.168.1.48"]="PLANTA - Redes TM - Sergio Pereyra - PC - CEVT-000836 - CPU-253"
  ["192.168.0.48"]="PLANTA - Redes TM - Sergio Pereyra - PC - CEVT-000836 - CPU-253"
  ["192.168.1.128"]="PLANTA - Redes TT - Franco Gasperin - IMPRESORA - HP M501 - CEVT-000910"
  ["192.168.0.123"]="PLANTA - Redes TT - Franco Gasperin - PC - CEVT-000841 - CPU-254"
  ["192.168.1.123"]="PLANTA - Redes TT - Franco Gasperin - PC - CEVT-000841 - CPU-254"
  ["192.168.0.98"]="PLANTA - Seguridad e Higiene - Nilda Cobo/Paula Acosta - PC - CEVT-000913 - CPU-272"
  ["192.168.1.98"]="PLANTA - Seguridad e Higiene - Nilda Cobo/Paula Acosta - PC - CEVT-000913 - CPU-272"
  ["192.168.0.80"]="PLANTA - Taller Mecanico - Javier Ledesma - PC - CEVT-000144 - CPU-078"
  ["192.168.1.80"]="PLANTA - Taller Mecanico - Javier Ledesma - PC - CEVT-000144 - CPU-078"
  ["192.168.0.126"]="Planta - Tecnica - Tableristas - CPU-264- TAB-GIS - Tableristas"
  ["192.168.1.126"]="Planta - Tecnica - Tableristas - CPU-264- TAB-GIS - Tableristas"
  ["192.168.1.204"]="RELOJ -  REPUESTO"
  ["192.168.1.206"]="RELOJ -  REPUESTO"
  ["192.168.1.201"]="RELOJ -  REPUESTO"
  ["192.168.1.202"]="RELOJ - ADMIN - Reloj biometrico - Personal"
  ["192.168.1.200"]="RELOJ - ADMIN - Reloj biometrico - Planta baja"
  ["192.168.1.203"]="RELOJ - FABRICA DE POSTES - Reloj biometrico"
  ["192.168.1.205"]="RELOJ - PLANTA - Reloj biometrico"
  ["192.168.0.1"]="ROUTER - ADMIN - 3 - Datacenter - CEVT-000122 - Oficina-CEVT (Puerto Enlace a Internet)"
  ["192.168.0.19"]="SERVER - ADMIN -  -1 - SubSuelo - Central Telefonica"
  ["192.168.0.7"]="SERVER - ADMIN - 3 - Datacenter - Cash Power"
  ["192.168.1.7"]="SERVER - ADMIN - 3 - Datacenter - Cash Power"
  ["192.168.1.21"]="SERVER - ADMIN - 3 - Datacenter - Server Linux"
  ["192.168.1.15"]="SERVER - ADMIN - 3 - Datacenter - Server UNIBIZ Aplicaciones"
  ["192.168.1.14"]="SERVER - ADMIN - 3 - Datacenter - Server UNIBIZ Base de datos"
  ["192.168.1.2"]="SERVER - ADMIN - 3 - Datacenter - Server Unix"
  ["192.168.1.3"]="SERVER - ADMIN - 3 - Datacenter - Server Unix HP II"
  ["192.168.0.4"]="SERVER - ADMIN - 3 - Datacenter - Server Unix Muleto"
  ["192.168.1.4"]="SERVER - ADMIN - 3 - Datacenter - Server Unix Muleto"
  ["192.168.1.6"]="SERVER - ADMIN - 3 - Datacenter -Server Linux"
  ["192.168.1.175"]="SERVER - ADMIN - 3 - Datacenter -Server Linux Red Hat"
  ["192.168.0.15"]="SERVER - ADMIN - 3 - Datacenter -Server UNIBIZ Aplicaciones"
  ["192.168.0.14"]="SERVER - ADMIN - 3 - Datacenter -Server UNIBIZ Base de datos"
  ["192.168.1.125"]="SINDICATO - Sepelio - Patricia Romero - IMPRESORA - RICOH M320F - CEVT-000918"
  ["192.168.1.83"]="SINDICATO - Sepelios - Patricia Romero - PC - CEVT-000422 - CPU-224"
  ["192.168.0.83"]="SINDICATO - Sepelios - Patricia Romero - PC - CEVT-000422 - CPU-224"
  ["192.168.1.82"]="SINDICATO - Sepelios - Repuesto - PC - CPU-223"
  ["192.168.1.169"]="SWITCH - ADMIN - -1 - Rack Aereo - CEVT-000743 - Cajas + Atencion a Usuarios"
  ["192.168.1.164"]="SWITCH - ADMIN - 1 - Sala de reuniones - CEVT-000571 - Segundo Piso"
  ["192.168.1.168"]="SWITCH - ADMIN - 2 - Facturacion - CEVT-000667 - Usuarios"
  ["192.168.1.162"]="SWITCH - ADMIN - 3 - Datacenter - CEVT-000545 - Datacencer-01"
  ["192.168.1.163"]="SWITCH - ADMIN - 3 - Datacenter - CEVT-000546 - Datacencer-02"
  ["192.168.1.161"]="SWITCH - ADMIN - 7 - Sistemas IT - CEVT-000544 - Oficinas Sistemas IT"
  ["192.168.1.165"]="SWITCH - PLANTA - Laboratorio - CEVT-000720 - Nodo Fibra Laboratorio"
  ["192.168.1.170"]="SWITCH - PLANTA - Laboratorio - CEVT-000721 - Nodo Fibra Laboratorio 2"
  ["192.168.1.167"]="SWITCH - PLANTA - Laboratorio - CEVT-000723 - Usina-Laboratorio"
  ["192.168.1.104"]="SWITCH - PLANTA - Laboratorio - Repuesto"
  ["192.168.1.160"]="SWITCH - PLANTA - Mediciones - CEVT-000566 - Mediciones-01"
  ["192.168.1.130"]="SWITCH - PLANTA - Reclamos - CEVT-001008 - Distribucion"
  ["192.168.1.166"]="SWITCH - PLANTA - Taller mecanico - CEVT-000722 - Usina-Taller"
  ["192.168.1.213"]="TRILOGYC - Mantenimiento y Desarollo - Adrian Sansone"
  ["192.168.0.213"]="TRILOGYC - Mantenimiento y Desarollo - Adrian Sansone"
  ["192.168.1.212"]="TRILOGYC - Mantenimiento y Desarollo - Hernan Lentino"
  ["192.168.0.212"]="TRILOGYC - Mantenimiento y Desarollo - Hernan Lentino"
  ["192.168.0.214"]="TRILOGYC - Mantenimiento y Desarollo - Marcelo Ivancich"
  ["192.168.1.214"]="TRILOGYC - Mantenimiento y Desarollo - Marcelo Ivancich"
  ["192.168.1.215"]="UNISOLUTIONS - Desarrollo - Carlos Durand"
  ["192.168.0.216"]="UNISOLUTIONS - Desarrollo - Liliana Peralta"
  ["192.168.1.216"]="UNISOLUTIONS - Desarrollo - Liliana Peralta"
)

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
  ["60666"]="SSH personalizado."
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
    declare -A portCount

    while IFS= read -r line; do
      while IFS='~' read -r local_time_adjusted logtype proto src_host src_port dst_host dst_port dst_port_desc node_id logdata; do
        # source attacker
        if [[ ! -v "sourceIP['${src_host}']" ]]; then
          if [[ "${logtype}" -ge ${LOW_DANGER_MSG_GE_THAN} ]]; then
            sourceIP["${src_host}"]=1
          fi
        else
          sourceIP["${src_host}"]=$((sourceIP["${src_host}"] + 1))
        fi
        # port count
        if [[ ! -v "portCount['${dst_port}']" ]]; then
          if [ "${logtype}" -ge 2000 ]; then
            portCount["${dst_port}"]=1
          fi
        else
          portCount["${dst_port}"]=$((portCount["${dst_port}"] + 1))
        fi
      done <<<"${line}"

    done <<<"${parsed}"

    source_stats_parsed=$(for k in "${!sourceIP[@]}"; do
      echo -e "${k}\t${sourceIP["${k}"]}\t${KnownUsers["${k}"]}"
    done |
      sort -t$'\t' -rn -k2)

    port_stats_parsed=$(for k in "${!portCount[@]}"; do
      echo -e "$k\t${portCount["${k}"]}\t${PortTCP["${k}"]}"
    done |
      sort -t$'\t' -rn -k2)

    # parsing first and last date
    fist_date=""
    line=$(head -n 1 <<<"${parsed}")
    while IFS='~' read -r local_time_adjusted logtype proto src_host src_port dst_host dst_port dst_port_desc node_id logdata; do
      fist_date="${local_time_adjusted}"
    done <<<"${line}"

    last_date=""
    line=$(tail -n 1 <<<"${parsed}")
    while IFS='~' read -r local_time_adjusted logtype proto src_host src_port dst_host dst_port dst_port_desc node_id logdata; do
      last_date="${local_time_adjusted}"
    done <<<"${line}"

    output="Período: ${fist_date} hasta ${last_date}\n"
    output+="\nIp con más problemas causados:\n\n"
    output+=$(echo -e "Origen\tProblemas\tDueño del IP\n${source_stats_parsed}" | column -ts $'\t')
    output+="\n\nPuerto más atacado:\n\n"
    #TODO    add support for UDP
    output+=$(echo -e "Puerto\tProblemas\tDescripción\n${port_stats_parsed}" | column -ts $'\t')

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
</table>
<br>
<hr>
<p>Estadística total de atacantes</p>
<pre>
  <code>
${stats}
  </code>
</pre>
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
        msgDanger=${msgDanger::-1}
        msgDanger+="]"
        # FORK function and continue
        echo "Listener Mailer: flag 3"
        sendMail "${msgDanger}" "1" &
        msgDanger="["
        counterDanger=0
        #    else
        #      echo "ignoring danger commit"
      fi
      if [[ $counterLow -gt 0 ]]; then
        msgLow=${msgLow::-1}
        msgLow+="]"
        # FORK function and continue
        sendMail "${msgLow}" "0" &
        msgLow="["
        counterLow=0
        #    else
        #      echo "ignoring low commit"
      fi
    else

      # ======= process line =======
      logType=$(jq '.logtype' <<<"${line}")
      logPort=$(jq '.dst_port' <<<"${line}" | tr -d '"')
      logProto=$(jq '.logdata.PROTO' <<<"${line}")

      isLowPriority=0

      #      echo "Listener Mailer: PORT: $logPort"
      #check if log must be low priority or not
      if [[ ${logProto} == *"TCP"* ]]; then
        #        echo "Listener Mailer: TCP DETECTED"
        if [[ $logPort != *"-1"* ]]; then
          #          echo "Listener Mailer: array = ${lowPriorityTCP[${logPort}]}"
          if [[ -n "${lowPriorityTCP[${logPort}]}" ]]; then
            #            echo "Listener Mailer: LOW PRIORITY TCP"
            isLowPriority=1
          fi
        fi
      fi
      if [[ "$logType" -lt "${LOW_DANGER_MSG_GE_THAN}" ]]; then
        isLowPriority=1
      fi

      #analyze if send mail is needed
      if [[ "$isLowPriority" -eq "0" ]]; then
        echo "Listener Mailer: MSG (HIGH) => ${line}"
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
        echo "Listener Mailer: MSG (LOW) => ${line}"
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

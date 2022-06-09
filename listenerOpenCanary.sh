#!/usr/bin/env bash
#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
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
  ["190.11.141.247"]="services.cevt.ar"
  ["190.11.141.249"]="Wifi 7mo"
  ["192.168.0.1"]="Admin - 3 Piso - Sistemas - Router  MikroTik-750G y RB2011UiAS - Puerto Enlace a Internet"
  ["192.168.0.4"]="Admin - 3 Piso - Sistemas - Server UNIX Muleto"
  ["192.168.1.213"]="Admin - 3 Piso - Sistemas -Trilogic - Adrian"
  ["192.168.0.14"]="Admin - 3 Piso - Sistemas - Server UniBiz-1 Oracle  - Win Svr 2008"
  ["192.168.0.9"]="Planta - Oficina tecnica - EX-SERVER-GIS - Back-OT"
  ["192.168.0.15"]="Admin - 3 Piso - Sistemas - Server UniBiz-2 Aplicaciones  - Win Svr 2008"
  ["192.168.1.212"]="Admin - 3 Piso - Sistemas -Trilogic -  Hernan"
  ["192.168.0.5"]="Admin - 3 Piso - Sistemas - Server UniBiz Muleto - DESARROLLO"
  ["192.168.1.175"]="Admin - 3 Piso - Sistemas - Server LINUX RED HAD"
  ["192.168.0.7"]="Admin - 3 Piso - Sistemas - Server CashPower"
  ["192.168.1.74"]="Planta - Laboratorio - CPU-205 - Jefe-Laboratorio- Nestor NIETO"
  ["192.168.1.76"]="Admin - 3 Piso - Personal - CPU-209-personal-2 - D.Bonfanti"
  ["192.168.1.75"]="Admin - 1 Piso - Secretaria Consejo"
  ["192.168.1.78"]="Admin - 8 Piso - Banda Ancha - CPU-277-ITT-Soporte - GIMENEZ, Mauricio Dario"
  ["192.168.1.77"]="Admin - 8 Piso - Banda Ancha - CPU-072-Banda-Ancha-2 - Mauricio Gimenez (Provisorio-CMTS)"
  ["192.168.0.22"]="Admin - 3 Piso - Sistemas - Raul Sanchez"
  ["192.168.0.139"]="Admin - 8 Piso - Legales"
  ["192.168.0.24"]="Admin - 7 Piso - Sistemas IT - CPU-271-sistemas-it  - Omar Pellegrini"
  ["192.168.1.79"]="Planta - Oficina Tecnica - OfiTec-2- CPU-274 - Marmiroli, Cristian"
  ["192.168.1.70"]="Admin - 0 P.Baja - Mesa Entrada - Recepcion  - CPU-227- Silvana Gimenez "
  ["192.168.1.72"]="Admin - 0 P.Baja - Cuentas a Cobrar - CPU-217-deudores-3 - Sebastian Pueigrredon"
  ["192.168.1.71"]="Admin - 0 P.Baja - Atencion Usuarios - Liliana COUX"
  ["192.168.0.252"]="Admin - 2 Piso - Usuarios - Colectores -Correa,A.- CPU-052"
  ["192.168.1.63"]="Admin - 2 Piso - Usuarios - Paula Viano"
  ["192.168.1.65"]="Admin - 0 P.Baja - Atencion Usuarios - Candida Medina - CPU-080"
  ["192.168.1.64"]="Admin - 0 P.Baja - Cuentas a Cobrar - CPU-216-deudores-2"
  ["192.168.0.98"]="Planta - Tecnica - Seguridad e Higiene"
  ["192.168.1.67"]="Admin - 3 Piso - Sistemas - CPU-054 - Procesamiento"
  ["192.168.1.66"]="Admin - 2 Piso - Usuarios - CPU-262-jefe-usuarios - Daniel Ureta"
  ["192.168.1.69"]="Admin - 3 Piso - Gerencia - A. Corradini- CPU-251-CEVT"
  ["192.168.1.68"]="Admin - 2 Piso - Usuarios - Fernanda Airasca"
  ["192.168.1.61"]="Admin - 3 Piso - Personal - CPU-258-personal-1 - Luisina ALI"
  ["192.168.0.120"]="Admin - 3 Piso - Sistemas - Monitoreo LAN - IpDiff"
  ["192.168.1.3"]="Admin - 3 Piso - Sistemas - Server UNIX HP II"
  ["192.168.1.2"]="Admin - 3 Piso - Sistemas - Server UNIX"
  ["192.168.1.9"]="Planta - Oficina tecnica - EX-SERVER-GIS - Back-OT"
  ["192.168.1.231"]="Admin - 3 Piso - Sistemas - Net-Security - BackUp y Servicios"
  ["192.168.1.49"]="Planta - Oficina Tecnica - GIS - CPU-085- Gustavo Bianco "
  ["192.168.1.48"]="Planta - Tecnica - Jefe Redes - TM - CPU-253 - S.Pereyra"
  ["192.168.1.5"]="Admin - 3 Piso - Sistemas - Server UniBiz Muleto - DESARROLLO"
  ["192.168.1.4"]="Admin - 3 Piso - Sistemas - Server UNIX Muleto"
  ["192.168.1.7"]="Admin - 3 Piso - Sistemas - Server CashPower"
  ["192.168.1.6"]="Admin - 3 Piso - Sistemas - Server LINUX"
  ["192.168.1.52"]="Planta - Oficina Tecnica - CPU-252 - jefe-ofitec - Fabian Arditti"
  ["192.168.1.51"]="Planta - Oficina tecnica -CPU-235- Ronco Mauricio"
  ["192.168.1.54"]="Planta - Oficina Tecnica - CPU-065- Juan Jose Fuentes Calvente"
  ["192.168.0.85"]="Planta - Taller Iluminacion- CPU-272-T-Ilumincion - Tarpin Marcelo (Guarda Focos)"
  ["192.168.1.56"]="Planta - Oficina tecnica -CPU-261-Hurtos-2- Suarez, Sebastian"
  ["192.168.0.87"]="Planta - Oficina Tecnica - Ing. Demarchi"
  ["192.168.0.88"]="Planta - Laboratorio - CPU-250 - Llopiz"
  ["192.168.1.55"]="Planta - Oficina Tecnica - GIS - CPU-221- Gustavo Bianco"
  ["192.168.1.57"]="Planta - Oficina Tecnica - Notebook -Programar Medidor"
  ["192.168.0.80"]="Planta - Taller Mecanico - Javier LEDESMA"
  ["192.168.0.81"]="Admin - 3 Piso - Secretaria - Ana Dominguez"
  ["192.168.1.50"]="Admin - 2 Piso - Rec-Pagos - CPU-014-pc-graciela - INTERBANKING  - ( Dar de Baja )"
  ["192.168.0.69"]="Admin - 3 Piso - Gerencia - A. Corradini - CPU-251-CEVT"
  ["192.168.1.38"]="Admin - 2 Piso - Contabilidad - CPU-203-contab-1 - Graciela Cossi"
  ["192.168.1.37"]="Admin - 2 Piso - Rec-Pagos - CPU-283-caja -  Central - Adrian Llopiz"
  ["192.168.1.101"]="Planta - Officina Tecnica - CPU-284-Estados-GP- Notebook-Oficina-Tecnica-M.Ronco"
  ["192.168.1.102"]="Admin - 2 Piso - Rec-Pagos - Impresora RED - HP-M400dn -  Cecilia-Silvana-Valeria"
  ["192.168.1.39"]="Admin - 0 P.Baja - Cuentas a Cobrar - Leandro Toselli"
  ["192.168.0.72"]="Admin - 0 P.Baja - Cuentas a Cobrar - CPU-217-deudores-3 - Sebastian Pueigrredon"
  ["192.168.1.40"]="Admin - 2 Piso - Rec-Pagos - CPU-068-rec-pagos - Cecilia Nievas"
  ["192.168.0.74"]="Planta - Laboratorio - CPU-205 - Jefe-Laboratorio- Nestor NIETO"
  ["192.168.1.43"]="Admin - 3 Piso - Sistemas - CPU-084- Factura - D.Mobilia"
  ["192.168.1.42"]="Admin - 2 Piso - Rec-Pagos - CPU-207-tesoreria - Rosana"
  ["192.168.0.75"]="Admin - 1 Piso - Secretaria Consejo"
  ["192.168.0.76"]="Admin - 3 Piso - Personal - CPU-209-personal-2 - D.Bonfanti"
  ["192.168.1.45"]="Admin - 2 Piso - Jefe Admin - CPU-208-Jefe-Admin - Dario Moreira"
  ["192.168.0.77"]="Admin - 8 Piso - Banda Ancha - CPU-072-Banda-Ancha-2 - Mauricio Gimenez (Provisorio-CMTS)"
  ["192.168.1.47"]="Planta - Almacenes - CPU-202-almacenes-Fernando RATTO"
  ["192.168.0.78"]="Admin - 8 Piso - Banda Ancha - CPU-277-ITT-Soporte - GIMENEZ, Mauricio Dario"
  ["192.168.1.46"]="Admin - 3 Piso - Sistemas - CPU-213 - Dardo Mobilia - Ex-Farre"
  ["192.168.0.71"]="Admin - 0 P.Baja - Atencion Usuarios - Liliana COUX"
  ["192.168.1.139"]="Admin - 8 Piso - Legales"
  ["192.168.1.27"]="Admin - 2 Piso - Rec-Pagos - CPU-074-rec-pagos-2 - Valeria Airasca"
  ["192.168.1.29"]="Admin - 2 Piso - Usuarios - Facturacion - Correa, Alejandra"
  ["192.168.1.28"]="Admin - 2 Piso - Rec-Pagos - CPU-075-rec-pagos-3 - Federico Basetti"
  ["192.168.1.252"]="Admin - 2 Piso - Usuarios - Colectores -Almaraz - CPU-052"
  ["192.168.1.30"]="Admin - 0 P.Baja - Cajero - Puesto Nº 1 - CPU-083 - Rossi, Nestor"
  ["192.168.1.32"]="Admin - 2 Piso - Usuarios - CPU-092-usuarios-3- TOME, Vanina"
  ["192.168.0.63"]="Admin - 2 Piso - Usuarios - Paula Viano"
  ["192.168.1.31"]="Admin - 3 Piso - Sistemas - Carlos Durand - CPU-088 -  Desarrolo UniBiz - DataCenter 3º Piso"
  ["192.168.0.64"]="Admin - 0 P.Baja - Cuentas a Cobrar - CPU-216-deudores-2"
  ["192.168.1.34"]="Admin - 3 Piso - Sistemas - Martin Vieguer - CPU-285-SISTEMA-2"
  ["192.168.0.66"]="Admin - 2 Piso - Usuarios - CPU-262-jefe-usuarios - Daniel Ureta"
  ["192.168.1.33"]="Admin - 2 Piso - Contabilidad - CPU-279-contab-jefe - Pia Corradini"
  ["192.168.0.67"]="Admin - 3 Piso - Sistemas - CPU-054 - Procesamiento"
  ["192.168.1.36"]="Admin - 2 Piso - Contabilidad - CPU-201- auditoria - C.Cavallero"
  ["192.168.1.35"]="Admin - 3 Piso - Compras - Walter Ruz - CPU-232"
  ["192.168.0.68"]="Admin - 2 Piso - Usuarios - Fernanda Airasca"
  ["192.168.0.213"]="Admin - 3 Piso - Sistemas -Trilogic - Adrian"
  ["192.168.0.212"]="Admin - 3 Piso - Sistemas -Trilogic -  Hernan"
  ["192.168.0.47"]="Planta - Almacenes - CPU-202-almacenes-Fernando RATTO"
  ["192.168.1.15"]="Admin - 3 Piso - Sistemas - Server UniBiz-2 Aplicaciones  - Win Svr 2008"
  ["192.168.0.48"]="Planta - Tecnica - Jefe Redes - TM - CPU-253 - S.Pereyra"
  ["192.168.0.49"]="Planta - Oficina Tecnica - GIS - CPU-085- Gustavo Bianco"
  ["192.168.1.120"]="Admin - 3 Piso - Sistemas - Monitoreo LAN - IpDiff"
  ["192.168.0.50"]="Admin - 2 Piso - Rec-Pagos - CPU-014-pc-graciela - INTERBANKING  - ( Dar de Baja )"
  ["192.168.0.51"]="Planta - Oficina tecnica -CPU-235- Ronco Mauricio"
  ["192.168.1.21"]="Admin - 3 Piso - Sistemas - Server LINUX"
  ["192.168.0.52"]="Planta - Oficina Tecnica - CPU-252 - jefe-ofitec - Fabian Arditti"
  ["192.168.0.54"]="Planta - Oficina Tecnica - CPU-065- Juan Jose Fuentes Calvente"
  ["192.168.1.22"]="Admin - 3 Piso - Sistemas - Raul Sanchez"
  ["192.168.0.55"]="Planta - Oficina Tecnica - GIS - CPU-221- Gustavo Bianco"
  ["192.168.0.56"]="Planta - Oficina tecnica -CPU-261-Hurtos-2- Suarez, Sebastian"
  ["192.168.1.25"]="Admin - 2 Piso - Rec-Pagos - CPU-231-proveedores - Pagos  - Cecilia"
  ["192.168.0.57"]="Planta - Oficina Tecnica - Notebook  -Programar Medidor"
  ["192.168.0.36"]="Admin - 2 Piso - Contabilidad - CPU-201- auditoria - C.Cavallero"
  ["192.168.0.37"]="Admin - 2 Piso - Rec-Pagos - CPU-283-caja -  Central - Adrian Llopiz"
  ["192.168.0.38"]="Admin - 2 Piso - Contabilidad - CPU-203-contab-1 - Graciela Cossi"
  ["192.168.0.39"]="Admin - 0 P.Baja - Cuentas a Cobrar - Leandro Toselli"
  ["192.168.0.40"]="Admin - 2 Piso - Rec-Pagos - CPU-068-rec-pagos - Cecilia Nievas"
  ["192.168.1.98"]="Planta - Tecnica - Seguridad e Higiene"
  ["192.168.0.42"]="Admin - 2 Piso - Rec-Pagos - CPU-207-tesoreria - Rosana"
  ["192.168.1.12"]="Planta - Laboratorio - NAS (BackUp Servers SISTEMAS)"
  ["192.168.0.43"]="Admin - 3 Piso - Sistemas - CPU-084- Factura - D.Mobilia"
  ["192.168.0.45"]="Admin - 2 Piso - Jefe Admin - CPU-208-Jefe-Admin - Dario Moreira"
  ["192.168.0.46"]="Admin - 3 Piso - Sistemas - CPU-213 - Dardo Mobilia - Ex-Farre"
  ["192.168.1.90"]="Admin - 0 P.Baja - Cajero - Puesto Nº 5 - CPU-061 - Antonela Ronco"
  ["192.168.1.92"]="Admin - 0 P.Baja - Cajero - Puesto Nº 2 - CPU-211 - Rossi, Roman"
  ["192.168.1.91"]="Admin - 0 P.Baja - Cajero - Puesto Nº 3 - CPU-089 - Mariano Carpaneti"
  ["192.168.1.94"]="Admin - 3 Piso - Personal - Impresora HP 402dne - Luisina"
  ["192.168.0.231"]="Admin - 3 Piso - Sistemas - Net-Security - BackUp y Servicios"
  ["192.168.1.93"]="Admin - 0 P.Baja - Cajero - Puesto Nº 4 - CPU-082 - Sonia Tisera"
  ["192.168.0.25"]="Admin - 2 Piso - Rec-Pagos - CPU-231-proveedores - Pagos  - Cecilia"
  ["192.168.0.26"]="Admin - 8 piso - RRHH - Notebook - Ariel Viano - TE. Int.1269"
  ["192.168.0.27"]="Admin - 2 Piso - Rec-Pagos - CPU-074-rec-pagos-2 - Valeria Airasca"
  ["192.168.0.28"]="Admin - 2 Piso - Rec-Pagos - CPU-075-rec-pagos-3 - Federico Basetti"
  ["192.168.0.29"]="Admin - 2 Piso - Usuarios - Facturacion - Correa, Alejandra"
  ["192.168.1.85"]="Planta - Taller Iluminacion- CPU-272-T-Ilumincion - Tarpin Marcelo (Guarda Focos)"
  ["192.168.1.87"]="Planta - Oficina Tecnica - Ing. Demarchi"
  ["192.168.0.31"]="Admin - 3 Piso - Sistemas - Carlos Durand - CPU-088 -  Desarrolo UniBiz - DataCenter 3º Piso"
  ["192.168.0.32"]="Admin - 2 Piso - Usuarios - CPU-092-usuarios-3- TOME, Vanina"
  ["192.168.0.33"]="Admin - 2 Piso - Contabilidad - CPU-279-contab-jefe - Pia Corradini"
  ["192.168.1.88"]="Planta - Laboratorio - CPU-250 - Llopiz"
  ["192.168.0.34"]="Admin - 3 Piso - Sistemas - Martin Vieguer - CPU-285-SISTEMA-2"
  ["192.168.0.35"]="Admin - 3 Piso - Compras - Walter Ruiz - CPU-232"
  ["192.168.0.101"]="Planta - Officina Tecnica - CPU-284-Estados-GP- Notebook-Oficina-Tecnica-M.Ronco"
  ["192.168.0.100"]="Planta - Tecnica - Telefonista - CPU-249 - Henry Viera"
  ["192.168.1.81"]="Admin - 3 Piso - Secretaria - Ana Dominguez"
  ["192.168.1.80"]="Planta - Taller Mecanico -  Javier LEDESMA"
  ["192.168.1.83"]="Admin - 0 . FIBRA - Seguros - Enlace Fibra Optica - Alvear 1161"
  ["192.168.1.82"]="Admin - 0 . FIBRA - Seguros-2 - Enlace Fibra Optica - Alvear 1161"
  ["192.168.1.201"]="RELOJ - Admin - 0 P.Baja - BioMetrico"
  ["192.168.1.86"]="Admin - 0 . FIBRA - COPAIN - CPU-079 - Fabrica de Postes"
  ["192.168.0.86"]="Admin - 0 . FIBRA - COPAIN - CPU-079 - Fabrica de Postes"
  ["192.168.1.204"]="RELOJ - Secco - Secco - BioMetrico"
  ["192.168.1.203"]="Admin - 0 . FIBRA - COPAIN - RELOJ - BioMetrico - Fabrica de Postes"
  ["192.168.1.202"]="RELOJ - Planta - Redes - BioMetrico"
  ["192.168.0.140"]="Admin - 3 Piso - Ing. CASABAT"
  ["192.168.1.215"]="Admin - 3 Piso - Sistemas - UniSolutions - NoteBook - DURAND, Carlos"
  ["192.168.1.96"]="Planta - Oficina Tecnica - Impresora-HURTOS - M.Ronco"
  ["192.168.1.200"]="RELOJ - Personal - 3 Piso - BioMetrico - BackUp"
  ["192.168.0.60"]="Admin - 0 P.Baja - Atencion Usuarios"
  ["192.168.1.60"]="Admin - 0 P.Baja - Atencion Usuarios"
  ["192.168.1.205"]="RELOJ - BackUp - 3 Piso - BioMetrico"
  ["192.168.0.58"]="Planta - Tecnica - Distribucion - CPU-247 - URDIALES, Pablo"
  ["192.168.1.58"]="Planta - Tecnica - Distribucion - CPU-247 - URDIALES, Pablo"
  ["192.168.1.8"]="Planta - Oficina Tecnica - Server GIS-Primario - CPU-230"
  ["192.168.0.8"]="Planta - Oficina Tecnica - Server GIS-Primario - CPU-230"
  ["192.168.0.17"]="Admin - 3 Piso - Sistemas - TURNOS - Server TURNOS Cajeros"
  ["192.168.1.17"]="Admin - 3 Piso - Sistemas - TURNOS - Server TURNOS Cajeros"
  ["192.168.1.14"]="Admin - 3 Piso - Sistemas - Server UniBiz-1 Oracle  - Win Svr 2008"
  ["192.168.1.24"]="Admin - 7 Piso - Sistemas IT - CPU-271-sistemas-it  - Omar Pellegrini"
  ["192.168.1.100"]="Planta - Tecnica - Telefonista - CPU-249 - Henry Viera"
  ["192.168.1.95"]="Planta - Laboratorio - Impresora RED - HP Color"
  ["192.168.1.97"]="Admin - 0 P.Baja - Cajero - Impresora HP por RED"
  ["192.168.1.99"]="Admin - 2 Piso - Contabilidad - Impresora RED -HP-M402dne - Graciela"
  ["192.168.1.26"]="Admin - 8 piso - RRHH - Notebook - Ariel Viano - TE. Int.1269"
  ["192.168.1.192"]="Admin - 0 P.Baja - TURNOS - TV-MiniCPU"
  ["192.168.1.104"]="Planta - Tecnica - SWITCH Secundario - HP 1920-24G - Distribucion"
  ["192.168.0.19"]="Admin - 0 . SubSuelo - CENTRAL TELEFONICA"
  ["192.168.0.216"]="Admin - 3 Piso - Sistemas - UniSolutions - NoteBook "
  ["192.168.1.216"]="Admin - 3 Piso - Sistemas - UniSolutions - NoteBook -  Liliana PERALTA - Desarrolladora de Unisolutions - Payroll"
  ["192.168.1.105"]="Admin - 3 piso - Sistemas - Impresora HP M203dw - Martin Vieguer"
  ["192.168.1.106"]="Admin - 3 piso - Sistemas - Impresora HP M401dn - Raul Sanchez"
  ["192.168.1.107"]="Admin - 2 Piso - Contabilidad - Impresora RED HP-M402nde - PIA"
  ["192.168.1.108"]="Admin - 0 P.Baja - Deudores - Impresora HP-p2035n - Sergio"
  ["192.168.1.109"]="Admin - 0 P.Baja - Deudores - Impresora  HP M401dn - Sergio-2"
  ["192.168.1.110"]="Admin - 3 piso - Sistemas - Impresora HP P4515n - Dardo - Martin"
  ["192.168.0.220"]="Admin - 3 piso - Sistemas - Server WEB CEVT - Oficina Virtual - CPU-245"
  ["192.168.1.18"]="Planta - Laboratorio - DVR - Camara Seguridad"
  ["192.168.1.73"]="Admin - 0 P.Baja - Mesa Entrada - Recepcion-2 - CPU-259 - Carpanetti, Cristian"
  ["192.168.1.44"]="Admin - 3 Piso - Sistemas - UniSolutions - CPU-268 -sistema3 - Desarrolo UniBiz - DataCenter 3º Piso"
  ["192.168.1.111"]="Admin - 0 P.Baja - Atencion Usuarios - Impresora MultiFuncion Brother"
  ["192.168.1.112"]="Admin - 3 Piso - Compras - Impresora MultiFuncion Brother - MFC-8950DW"
  ["192.168.1.114"]="Planta - Laboratorio - Impresora RED HP M402dn"
  ["192.168.1.113"]="Admin - 3 Piso - Sistemas - Impresora MultiFuncion Brother -  DCP-L2540DW"
  ["192.168.0.250"]="Admin - 1 Piso - Sala Reuniones - CAPACITACION - CPU-236"
  ["192.168.1.250"]="Admin - 1 Piso - Sala Reuniones - CAPACITACION - CPU-236"
  ["192.168.0.53"]="Admin - 3 Piso - Sistemas - CPU-009 -  Server IMPRESION - RECEPCION+CTAS.aCOBRAR"
  ["192.168.1.53"]="Admin - 3 Piso - Sistemas - CPU-009 - Server IMPRESION - RECEPCION+CTAS.aCOBRAR"
  ["192.168.0.70"]="Admin - 0 P.Baja - Mesa Entrada - Recepcion  - CPU-227- Silvana Gimenez "
  ["192.168.1.115"]="Admin - 3 Piso - Secretaria - Impresora HP-M452dw COLOR"
  ["192.168.1.62"]="Admin - 2 Piso - Usuarios - Laura Viano"
  ["192.168.0.62"]="Admin - 2 Piso - Usuarios - Laura Viano"
  ["192.168.0.122"]="Planta - Tecnica - Reclamos - CPU-246- Viera Henrri"
  ["192.168.1.122"]="Planta - Tecnica - Reclamos - CPU-246- Viera Henrri"
  ["192.168.1.125"]="Planta - Tecnica - Impresora MultiFuncion Brother DCP-2540dw"
  ["192.168.0.20"]="Admin - 3 Piso - Sistemas - Server QNAP - TS-431p - CPU-267-qnap-1"
  ["192.168.0.214"]="Admin - 3 Piso - Sistemas -Trilogic -  Marcelo"
  ["192.168.1.214"]="Admin - 3 Piso - Sistemas -Trilogic -  Marcelo"
  ["192.168.0.23"]="Admin - 2 Piso - Usuarios - Colectores - Alejandra"
  ["192.168.1.23"]="Admin - 2 Piso - Usuarios - Colectores - Alejandra"
  ["192.168.0.65"]="Admin - 0 P.Baja - Atencion Usuarios - Candida Medina - CPU-080"
  ["192.168.1.16"]="Admin - 3 Piso - Sistemas - NAS-2 - Linux - Imagen de IP 14 y 15"
  ["192.168.0.59"]="Planta - Oficina Tecnica - GIS - CPU-248- Martin Ureta"
  ["192.168.1.59"]="Planta - Oficina Tecnica - GIS - CPU-248- Martin Ureta"
  ["192.168.0.123"]="Planta - Tecnica - Jefe Redes - TT- CPU-254 - Leandro CENCI"
  ["192.168.1.123"]="Planta - Tecnica - Jefe Redes - TT- CPU-254 - Leandro CENCI"
  ["192.168.0.124"]="Planta - Oficina Tecnica - Mediciones - CPU-256- JJ.Fuentes Calvente"
  ["192.168.1.124"]="Planta - Oficina Tecnica - Mediciones - CPU-256- JJ.Fuentes Calvente"
  ["192.168.0.61"]="Admin - 3 Piso - Personal - CPU-258-personal-1 - Luisina ALI"
  ["192.168.0.73"]="Admin - 0 P.Baja - Mesa Entrada - Recepcion-2 - CPU-259 - Carpanetti, Cristian"
  ["192.168.1.193"]="Admin - 0 P.Baja - TURNOS - TICKEADORA - Pantalla"
  ["192.168.0.193"]="Admin - 0 P.Baja - TURNOS - TICKEADORA - Pantalla"
  ["192.168.0.141"]="Admin - 0 . SubSuelo - Mantenimiento - CPU-069 - Damian Miscoff"
  ["192.168.1.141"]="Admin - 0 . SubSuelo - Mantenimiento - CPU-069 - Damian Miscoff"
  ["192.168.0.142"]="Admin - 8 Piso - Banda Ancha - CPU-260-Banda-Ancha - Javier GATTI"
  ["192.168.1.142"]="Admin - 8 Piso - Banda Ancha - CPU-260-Banda-Ancha - Javier GATTI"
  ["192.168.1.116"]="Admin - 2 Piso - PASILLO - Impresora MultiFuncion Brother - DCP-L5600DN"
  ["192.168.1.20"]="Admin - 3 Piso - Sistemas - Server QNAP - TS-431p - CPU-267-qnap-1"
  ["192.168.1.117"]="Planta - Oficina Tecnica - CPU-064-g-potencia - Fabian Arditti (Lotus-Grandes Potencias)"
  ["192.168.1.118"]="Admin - 3 piso - Sistemas - Impresora HP M402dn - Omar Pellegrini - CPU-271"
  ["192.168.0.44"]="Admin - 3 Piso - Sistemas - UniSolutions - CPU-268 -sistema3 - Desarrolo UniBiz - DataCenter 3º Piso"
  ["192.168.1.103"]="Admin - 2 Piso - Usuarios - Impresora RED LexMark - MS810 - Facturacion"
  ["192.168.1.206"]="RELOJ - BackUp 2 - Host: reloj-206  - BioMetrico"
  ["192.168.0.150"]="Admin - 7 Piso - Sistemas IT - Franco Pellegrini - CPU-269-desarrollo-IT"
  ["192.168.1.150"]="Admin - 7 Piso - Sistemas IT - Franco Pellegrini - CPU-269-desarrollo-IT"
  ["192.168.1.143"]="Admin - 2 Piso - Rec-Pagos - CPU-220-rec-pagos-4 - INTERBANKING  - Federico + Cecilia "
  ["192.168.0.143"]="Admin - 2 Piso - Rec-Pagos - CPU-220-rec-pagos-4 - INTERBANKING  - Federico + Cecilia "
  ["192.168.0.84"]="Admin - 1 Piso - Oficina - Presidencia - CPU-077"
  ["192.168.1.84"]="Admin - 1 Piso - Oficina - Presidencia - CPU-077"
  ["192.168.0.254"]="Admin - 7 Piso - Sistemas IT -  Omar Pellegrini  - Sistemas-IT - Instalacion CPU y Mantenimiento"
  ["192.168.1.254"]="Admin - 7 Piso - Sistemas IT -  Omar Pellegrini  - Sistemas-IT - Instalacion CPU y Mantenimiento"
  ["192.168.0.41"]="Planta - Tecnica - Distribucion - NOTEBOOK - URDIALES, Pablo"
  ["192.168.1.41"]="Planta - Tecnica - Distribucion - NOTEBOOK - URDIALES, Pablo"
  ["192.168.0.217"]="Planta - Oficina Tecnica - GIS - NoteBook - Mario PERELLO - LUJAN"
  ["192.168.1.217"]="Planta - Oficina Tecnica - GIS - NoteBook - Mario PERELLO - LUJAN"
  ["192.168.0.155"]="Admin - 7 Piso - Sistemas IT - Franco Pellegrini - NoteBook - Linux - Desarrollo IT"
  ["192.168.0.126"]="Planta - Tecnica - Tableristas - CPU-264- Tableristas"
  ["192.168.1.126"]="Planta - Tecnica - Tableristas - CPU-264- Tableristas"
  ["192.168.0.117"]="Planta - Oficina Tecnica - CPU-064-g-potencia - Fabian Arditti (Lotus-Grandes Potencias)"
  ["192.168.0.13"]="Planta - Oficina Tecnica - Server GIS -CPU-230-gis"
  ["192.168.1.13"]="Planta - Oficina Tecnica - Server GIS -CPU-230-gis"
  ["192.168.1.119"]="Admin - 3 Piso - Personal - Impresora HP M402dne - Bonfanti Daniel"
  ["192.168.0.251"]="Admin - 3 Piso - Sistemas - Sistemas-IT - IMPRESORAS , Pruebas, Configuracion y Mantenimiento"
  ["192.168.1.144"]="Admin - 0 P.Baja - Atencion Usuarios - Puesto 4"
  ["192.168.0.144"]="Admin - 0 P.Baja - Atencion Usuarios - Puesto 4"
  ["192.168.1.145"]="Admin - 0 P.Baja - Atencion Usuarios - CPU- . . . - Impresora HP M404dw - Puesto 4"
  ["192.168.1.146"]="Admin - 0 P.Baja - Atencion Usuarios - CPU-.... - Impresora HP M404dw - Puesto 3"
  ["192.168.1.147"]="Admin - 2 Piso - Usuarios - Impresora RED - HP M404dwn  - CPU-"
  ["192.168.1.148"]="Admin - 2 Piso - Usuarios - Impresora RED - HP M404dwn  - CPU-"
  ["192.168.0.79"]="Planta - Oficina Tecnica - OfiTec-2- CPU-274 - Marmiroli, Cristian"
  ["192.168.1.149"]="Admin - 0 P.Baja - Cuentas a Cobrar - CPU-217-deudores-3 - IMPRESORA - Sebastian Pueigrredon"
  ["192.168.0.157"]="Admin - 3 Piso - Sistemas - Federico RUIZ - CPU-275-Sistemas-Procesamiento"
  ["192.168.1.157"]="Admin - 3 Piso - Sistemas - Federico RUIZ - CPU-275-Sistemas-Procesamiento"
  ["192.168.1.121"]="Planta - Tecnica - Impresora - HP-M501dn - Reclamos y Telefonista"
  ["192.168.1.128"]="Planta - Tecnica - Jefe Redes - TT- CPU-254 - Leandro CENCI -  Impresora - HP-M501dn"
  ["192.168.1.127"]="Planta - Tecnica - Jefe Redes - TM - CPU-253 - S.Pereyra -  Impresora - HP-M501dn"
  ["192.168.1.130"]="Planta - Tecnica - SWITCH PRINCIPAL - CISCO-24G - Distribucion (User:CEVT-PLANTA ->planta-cevt-2021)"
  ["192.168.1.158"]="Admin - 2 Piso - Usuarios - Impresora RED - HP LaserJet M203dw - CPU-086  - Paula Viano y Yanina Tome"
  ["192.168.0.129"]="Planta - Tecnica - Jefe Redes - TM - CPU-278-redes-tm-2  - Cristian Martinez (Suplente)"
  ["192.168.1.129"]="Planta - Tecnica - Jefe Redes - TM - CPU-278-redes-tm-2  - Cristian Martinez (Suplente)"
  ["192.168.1.151"]="Admin - 0 P.Baja - Atencion Usuarios - CPU-080 - Impresora HP M404dw (Nº Serie: BRBSMCVN07) - Puesto 2"
  ["192.168.1.152"]="Admin - 3 Piso - Sistemas - Impresora RED - HP LaserJet M203dw - REPUESTO EMERGENCIASme"
  ["192.168.0.138"]="Admin - 3 Piso - Personal - CPU-276 -personal-3  -  Angelo Rossi -  (Admin:cintia)"
  ["192.168.1.138"]="Admin - 3 Piso - Personal - CPU-276 -personal-3  -  Angelo Rossi -  (Admin:cintia)"
  ["192.168.0.131"]="Planta - Laboratorio - CPU-281-Laboratorio-3 - Pozuelo, Luis"
  ["192.168.1.131"]="Planta - Laboratorio - CPU-281-Laboratorio-3 - Pozuelo, Luis"
  ["192.168.1.153"]="Admin - 3 piso - Sistemas - Impresora HP M401dn - RUIZ, Federico - CPU-275"
  ["192.168.1.156"]="Admin - 7 Piso - Sistemas IT - CPU-263-soporte-it  - Martin ROSSI"
  ["192.168.0.156"]="Admin - 7 Piso - Sistemas IT - CPU-263-soporte-it  - Martin ROSSI"
  ["192.168.1.154"]="Admin - 3 Piso - Sistemas - M.Vieguer - CPU-206 -  Facturas-OnLine - DataCenter  3º  Piso"
  ["192.168.0.154"]="Admin - 3 Piso - Sistemas - M.Vieguer - CPU-206 -  Facturas-OnLine - DataCenter  3º  Piso"
  ["192.168.0.137"]="Admin - 3 Piso - Personal - CPU-282 -personal-4  -  Daniel Bonfanti "
  ["192.168.1.137"]="Admin - 3 Piso - Personal - CPU-282 -personal-4  -  Daniel Bonfanti "
  ["192.168.1.132"]="Admin - 2 Piso - Rec-Pagos - Impresora RED - HP M404dw - CPU-220- INTERBANKING - Federico"
  ["192.168.1.161"]="Admin - 7 Piso - Sistemas IT - SWITCH - Sistemas-it  - CEVT-000544 - MikroTik CSS610-8G-2S+IN"
  ["192.168.1.162"]="Admin - 3 Piso - Sistemas - SWITCH - DataCenter-01 - CEVT-000545 - MikroTik CSS326-24G-2S+RM"
  ["192.168.1.163"]="Admin - 3 Piso - Sistemas - SWITCH - DataCenter-01 - CEVT-000546 - MikroTik CSS326-24G-2S+RM"
  ["192.168.0.232"]="Admin - 7 Piso - Sistemas IT - Monitoreo"
  ["192.168.1.232"]="Admin - 7 Piso - Sistemas IT - Monitoreo"
  ["192.168.0.253"]="Admin - 7 Piso - Sistemas IT - Franco Pellegrini - Raspberry Pi 400 - Honeypot"
  ["192.168.1.253"]="Admin - 7 Piso - Sistemas IT - Franco Pellegrini - Raspberry Pi 400 - Honeypot"
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

#!/usr/bin/env bash

#
# Copyright (c) 2023. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

includeScriptName="include.sh"

ME=$(basename "$0")

DATE_FORMAT="+%d/%m/%y - %H:%M:%S"

#https://misc.flogisoft.com/bash/tip_colors_and_formatting
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NOCOLOR="\033[0m"

function formatTextToLog() {
  local color
  local data
  local file
  local currentDate
  currentDate=$(date "${DATE_FORMAT}")
  color=$1
  title=$2
  infoType=$3
  data=$4
  file=${ME}
  if [ "${color}" = "${NOCOLOR}" ]; then
    echo "${currentDate} = ${file}: [${infoType}] ${title} => ${data}"
  else
    echo -e "${color}${currentDate} = ${file}: [${infoType}] ${title} => ${data}${NOCOLOR}"
  fi
}

function echoInfo() {
  formatTextToLog "${GREEN}" "$1" "INFO" "$2"
}

function echoWarning() {
  formatTextToLog "${YELLOW}" "$1" "WARNING" "$2"
}

function echoError() {
  formatTextToLog "${RED}" "$1" "ERROR" "$2"
}

SYSTEM_ERROR_LOG_DIR="/var/log/cevt"
ERROR_LOG_FILE_NAME="ERRORS.log"
SCRIPT_LOG_FILE_NAME="script.log"

function logInfo() {
  while read -r data; do
    echoInfo "$1" "${data}"
    formatTextToLog "${NOCOLOR}" "$1" "INFO" "${data}" >>"${SCRIPT_LOG_FILE}"
  done
}

function logWarning() {
  while read -r data; do
    echoWarning "$1" "${data}"
    formatTextToLog "${NOCOLOR}" "$1" "WARNING" "${data}" >>"${SCRIPT_LOG_FILE}"
  done
}

function logError() {
  while read -r data; do
    echoError "$1" "${data}"
    formatTextToLog "${NOCOLOR}" "$1" "ERROR" "${data}" >>"${SCRIPT_LOG_FILE}"
    formatTextToLog "${NOCOLOR}" "$1" "ERROR" "${data}" >>"${ERROR_LOG_FILE}"
  done
}

mkdir -p "${SYSTEM_ERROR_LOG_DIR}"
ERROR_LOG_FILE="${SYSTEM_ERROR_LOG_DIR}/${ERROR_LOG_FILE_NAME}"
SCRIPT_LOG_FILE="${SYSTEM_ERROR_LOG_DIR}/${SCRIPT_LOG_FILE_NAME}"

function truncateLog() {
  TEMPLOG=$(mktemp)
  tail -100000 "${SCRIPT_LOG_FILE}" >"${TEMPLOG}"
  cp "${TEMPLOG}" "${SCRIPT_LOG_FILE}"
  rm -f "${TEMPLOG}"
}

function logErrorFromLines() {
  while read -r line; do
    if [ -n "${line}" ]; then
      echo "${line}" | logError "${1}"
    fi
  done <<<"${2}"
}

function checkIfNoErrors() {
  local errors=0
  while read -r line; do
    if [ -n "${line}" ]; then
      echo "${line}" | logError "${1}"
      ((errors = errors + 1))
    fi
  done <<<"${2}"
  if ((errors > 0)); then
    return 100
  else
    return 0
  fi
}

function commentLine() {
  local TARGET_PATTERN=${1}
  local COMMENT_SYMBOL=${2}
  local CONFIG_FILE=${3}
  echoInfo "commentLine" "${CONFIG_FILE}: pattern to comment ${TARGET_PATTERN} with symbol ${COMMENT_SYMBOL}"
  sed -i "/^[^${COMMENT_SYMBOL}]/ s/\(^.*${TARGET_PATTERN}.*$\)/${COMMENT_SYMBOL}\ \1/" "${CONFIG_FILE}"
  echoInfo "commentLine" "sed -i \"/![^${COMMENT_SYMBOL}]/ s/\(^.*${TARGET_PATTERN}.*$\)/${COMMENT_SYMBOL}\ \1/\" ${CONFIG_FILE}"
}

function replaceConfVar() {
  local TARGET_KEY
  local REPLACEMENT_VALUE
  local CONFIG_FILE
  TARGET_KEY=$(echo "${1}" | sed 's/\//\\\//g')
  REPLACEMENT_VALUE=$(echo "${2}" | sed 's/\//\\\//g')
  CONFIG_FILE=${3}
  echoInfo "replaceConfVar" "${CONFIG_FILE}: ${TARGET_KEY} -> ${REPLACEMENT_VALUE}"
  sed -i "s/^\#* *\(${TARGET_KEY} *= *\).*$/${TARGET_KEY} = ${REPLACEMENT_VALUE}/" "${CONFIG_FILE}"
  echoInfo "replaceConfVar" "sed -i s/^\#* *\(${TARGET_KEY} *= *\).*$/${TARGET_KEY} = ${REPLACEMENT_VALUE}/ ${CONFIG_FILE}"
}

function replaceConfVarFirstMatch() {
  local TARGET_KEY
  local REPLACEMENT_VALUE
  local FROM
  local CONFIG_FILE
  TARGET_KEY=$(echo "${1}" | sed 's/\//\\\//g')
  REPLACEMENT_VALUE=$(echo "${2}" | sed 's/\//\\\//g')
  FROM=$(echo "${3}" | sed 's/\//\\\//g')
  CONFIG_FILE=${4}

  echoInfo "replaceConfVarFirstMatch" "From ${FROM}: ${CONFIG_FILE}: ${TARGET_KEY} -> ${REPLACEMENT_VALUE}"
  echoInfo "replaceConfVarFirstMatch" "sed -i \"/${FROM}/,/${TARGET_KEY} *= */s/\(${TARGET_KEY} *= *\).*/\1${REPLACEMENT_VALUE}/\" ${CONFIG_FILE}"
  sed -i "/${FROM}/,/${TARGET_KEY} *= */s/\(${TARGET_KEY} *= *\).*/\1${REPLACEMENT_VALUE}/" "${CONFIG_FILE}"
}

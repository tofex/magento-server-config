#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Web path
  -u  Web user
  -g  Web group
  -s  Merge script (required if Magento 1)
  -i  Merge script PHP script (required if Magento 1)
  -j  Add PHP script (required if Magento 2)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs -j /tmp/script.php
EOF
}

trim()
{
  echo -n "$1" | xargs
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
webPath=
webUser=
webGroup=
adminPath=
mergeScript=
mergeScriptPhpScript=
addScript=

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:s:i:j:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    s) mergeScript=$(trim "$OPTARG");;
    i) mergeScriptPhpScript=$(trim "$OPTARG");;
    j) addScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No web action required for Magento ${magentoVersion}"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  magento2EnvironmentFile="${webPath}/app/etc/env.php"

  if [[ -L "${magento2EnvironmentFile}" ]]; then
    magento2EnvironmentFile=$(readlink -f "${magento2EnvironmentFile}")
  fi

  if [[ -f "${magento2EnvironmentFile}" ]]; then
    magento2ConfigPath=$(dirname "${magento2EnvironmentFile}")

    if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.2.0") == 2 ]]; then
      php "${addScript}" "${magento2ConfigPath}" "directories/document_root_is_pub" true
    else
      echo "Nothing to add for Magento ${magentoVersion}"
    fi
  fi
fi

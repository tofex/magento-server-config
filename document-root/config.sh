#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --magentoVersion     Magento version
  --webPath            Web path
  --webUser            Web user
  --webGroup           Web group
  --documentRootIsPub  Flag if pub folder is root directory (yes/no), default: yes
  --addScript          Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.3.7 --webPath /var/www/magento/htdocs --addScript /tmp/script.php
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
documentRootIsPub=
addScript=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

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

if [[ -z "${documentRootIsPub}" ]]; then
  documentRootIsPub="yes"
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
      if [[ "${documentRootIsPub}" == "yes" ]]; then
        echo "Setting document root to pub directory"
        php "${addScript}" "${magento2ConfigPath}" "directories/document_root_is_pub" true
      else
        echo "Setting document root not to pub directory"
        php "${addScript}" "${magento2ConfigPath}" "directories/document_root_is_pub" false
      fi
    else
      echo "Nothing to set for Magento version: ${magentoVersion}"
    fi
  fi
fi

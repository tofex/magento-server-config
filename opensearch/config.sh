#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --environment           Name of environment (optional)
  --magentoVersion        Magento version
  --openSearchEngine      Search engine, default: core
  --openSearchVersion     OpenSearch version
  --openSearchHost        OpenSearch host
  --openSearchPort        OpenSearch port
  --openSearchPrefix      Index Prefix
  --openSearchUser        OpenSearch user (optional)
  --openSearchPassword    OpenSearch password (optional)
  --webPath               Web path
  --webUser               Web user (optional)
  --webGroup              Web group (optional)
  --mergeScript           Merge script (required if Magento 1)
  --mergeScriptPhpScript  Merge script PHP script (required if Magento 1)
  --addScript             Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.4.5 --openSearchVersion 2.9  --openSearchHost localhost --openSearchPort 9200 --webPath /var/www/magento/htdocs --addScript /tmp/add.php
EOF
}

environment=
magentoVersion=
openSearchEngine=
openSearchVersion=
openSearchHost=
openSearchPort=
openSearchPrefix=
openSearchUser=
openSearchPassword=
webPath=
webUser=
webGroup=
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

if [[ -z "${openSearchEngine}" ]]; then
  openSearchEngine="core"
fi

if [[ -z "${openSearchVersion}" ]]; then
  echo "No OpenSearch version specified!"
  usage
  exit 1
fi

if [[ -z "${openSearchHost}" ]]; then
  echo "No OpenSearch host specified!"
  usage
  exit 1
fi

if [[ -z "${openSearchPort}" ]]; then
  echo "No OpenSearch port specified!"
  usage
  exit 1
fi

if [[ -z "${openSearchPrefix}" ]]; then
  echo "No OpenSearch prefix specified!"
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

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No default OpenSearch integration in Magento 1"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  if [[ -n "${environment}" ]]; then
    magento2ConfigFile="${webPath}/app/etc/env/${environment}.php"
  else
    magento2ConfigFile="${webPath}/app/etc/config.php"
  fi

  if [[ -e "${magento2ConfigFile}" ]]; then
    if [[ -L "${magento2ConfigFile}" ]]; then
      magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
    fi

    if [[ -f "${magento2ConfigFile}" ]]; then
      if [[ "${openSearchEngine}" == "core" ]]; then
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "opensearch"
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_server_hostname" "${openSearchHost}"
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_server_port" "${openSearchPort}"
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_index_prefix" "${openSearchPrefix}"
        if [[ -n "${openSearchUser}" ]] && [[ -n "${openSearchPassword}" ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_enable_auth" 1
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_username" "${openSearchUser}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/opensearch_password" "${openSearchPassword}"
        fi
      else
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "${openSearchEngine}"
      fi

      cd "${webPath}"
      bin/magento app:config:import
    else
      >&2 echo "Configuration file not found at: ${magento2ConfigFile}"
      exit 1
    fi
  else
    >&2 echo "Configuration file not found at: ${magento2ConfigFile}"
    exit 1
  fi
fi

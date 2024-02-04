#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                   Show this message
  --magentoVersion         Magento version
  --elasticsearchEngine    Search engine, default: core
  --elasticsearchVersion   Elasticsearch version
  --elasticsearchHost      Elasticsearch host
  --elasticsearchPort      Elasticsearch port
  --elasticsearchPrefix    Index Prefix
  --elasticsearchUser      Elasticsearch user (optional)
  --elasticsearchPassword  Elasticsearch password (optional)
  --webPath                Web path
  --webUser                Web user (optional)
  --webGroup               Web group (optional)
  --mergeScript            Merge script (required if Magento 1)
  --mergeScriptPhpScript   Merge script PHP script (required if Magento 1)
  --addScript              Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.4.5 --elasticsearchVersion 7.9  --elasticsearchHost localhost --elasticsearchPort 9200 --webPath /var/www/magento/htdocs --addScript /tmp/add.php
EOF
}

magentoVersion=
elasticsearchEngine=
elasticsearchVersion=
elasticsearchHost=
elasticsearchPort=
elasticsearchPrefix=
elasticsearchUser=
elasticsearchPassword=
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

if [[ -z "${elasticsearchEngine}" ]]; then
  elasticsearchEngine="core"
fi

if [[ -z "${elasticsearchVersion}" ]]; then
  echo "No Elasticsearch version specified!"
  usage
  exit 1
fi

if [[ -z "${elasticsearchHost}" ]]; then
  echo "No Elasticsearch host specified!"
  usage
  exit 1
fi

if [[ -z "${elasticsearchPort}" ]]; then
  echo "No Elasticsearch port specified!"
  usage
  exit 1
fi

if [[ -z "${elasticsearchPrefix}" ]]; then
  echo "No Elasticsearch prefix specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

elasticsearchMainVersion="${elasticsearchVersion%.*}"

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No default Elasticsearch integration in Magento 1"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  if [[ -n "${PROJECT_ENV}" ]]; then
    magento2ConfigFile="${webPath}/app/etc/env/${PROJECT_ENV}.php"
  else
    magento2ConfigFile="${webPath}/app/etc/config.php"
  fi

  if [[ -e "${magento2ConfigFile}" ]]; then
    if [[ -L "${magento2ConfigFile}" ]]; then
      magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
    fi

    if [[ -f "${magento2ConfigFile}" ]]; then
      if [[ "${elasticsearchEngine}" == "core" ]]; then
        if [[ "${elasticsearchMainVersion}" == 5 ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "elasticsearch5"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_server_hostname" "${elasticsearchHost}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_server_port" "${elasticsearchPort}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_index_prefix" "${elasticsearchPrefix}"
          if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_enable_auth" 1
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_username" "${elasticsearchUser}"
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch5_password" "${elasticsearchPassword}"
          fi
        elif [[ "${elasticsearchMainVersion}" == 6 ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/engine" "elasticsearch6"
          php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_server_hostname" "${elasticsearchHost}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_server_port" "${elasticsearchPort}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_index_prefix" "${elasticsearchPrefix}"
          if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
            php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_enable_auth" 1
            php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_username" "${elasticsearchUser}"
            php "${addScript}" "${magento2ConfigFile}" "system/default/system/default/catalog/search/elasticsearch6_password" "${elasticsearchPassword}"
          fi
        elif [[ "${elasticsearchMainVersion}" == 7 ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "elasticsearch7"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_server_hostname" "${elasticsearchHost}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_server_port" "${elasticsearchPort}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_index_prefix" "${elasticsearchPrefix}"
          if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_enable_auth" 1
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_username" "${elasticsearchUser}"
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch7_password" "${elasticsearchPassword}"
          fi
        else
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "elasticsearch"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_server_hostname" "${elasticsearchHost}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_server_port" "${elasticsearchPort}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_index_prefix" "${elasticsearchPrefix}"
          if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_enable_auth" 1
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_username" "${elasticsearchUser}"
            php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/elasticsearch_password" "${elasticsearchPassword}"
          fi
        fi
      else
        php "${addScript}" "${magento2ConfigFile}" "system/default/catalog/search/engine" "${elasticsearchEngine}"
        if [[ "${elasticsearchEngine}" == "elasticsuite" ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/smile_elasticsuite_core_base_settings/es_client/servers" "${elasticsearchHost}:${elasticsearchPort}"
          if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
            php "${addScript}" "${magento2ConfigFile}" "system/default/smile_elasticsuite_core_base_settings/es_client/enable_http_auth" 1
            php "${addScript}" "${magento2ConfigFile}" "system/default/smile_elasticsuite_core_base_settings/es_client/http_auth_user" "${elasticsearchUser}"
            php "${addScript}" "${magento2ConfigFile}" "system/default/smile_elasticsuite_core_base_settings/es_client/http_auth_pwd" "${elasticsearchPassword}"
          fi
        fi
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

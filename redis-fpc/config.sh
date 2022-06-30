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
  --redisFPCHost           Redis FPC host
  --redisFPCPort           Redis FPC port
  --redisFPCPassword       Redis FPC password (optional)
  --redisFPCDatabase       Redis FPC database
  --redisFPCCachePrefix    Redis FPC prefix, default: fpc_
  --redisFPCClassName      Redis FPC class name, default: Cm_Cache_Backend_Redis
  --webPath                Web path
  --webUser                Web user
  --webGroup               Web group
  --mergeScript            Merge script (required if Magento 1)
  --mergeScriptPhpScript   Merge script PHP script (required if Magento 1)
  --addScript              Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.3.7 --redisFPCHost localhost --redisFPCPort 6379 --redisFPCDatabase 0 --addScript /tmp/add.php
EOF
}

magentoVersion=
redisFPCHost=
redisFPCPort=
redisFPCPassword=
redisFPCDatabase=
redisFPCCachePrefix=
redisFPCClassName=
webPath=
webUser=
webGroup=

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

if [[ -z "${redisFPCHost}" ]]; then
  echo "No Redis FPC host specified!"
  usage
  exit 1
fi

if [[ -z "${redisFPCPort}" ]]; then
  echo "No Redis FPC port specified!"
  usage
  exit 1
fi

if [[ -z "${redisFPCDatabase}" ]]; then
  echo "No Redis FPC database specified!"
  usage
  exit 1
fi

if [[ -z "${redisFPCCachePrefix}" ]]; then
  redisFPCCachePrefix="fpc_"
fi

if [[ -z "${redisFPCClassName}" ]]; then
  redisFPCClassName="Cm_Cache_Backend_Redis"
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
  # Magento 1
  if [[ -z "${mergeScript}" ]]; then
    echo "No merge script specified!"
    usage
    exit 1
  fi

  if [[ -z "${mergeScriptPhpScript}" ]]; then
    echo "No merge script PHP script specified!"
    usage
    exit 1
  fi

  magento1ConfigFile="${webPath}/app/etc/local.xml"

  if [[ -e "${magento1ConfigFile}" ]]; then
    if [[ -L "${magento1ConfigFile}" ]]; then
      magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
    fi

    if [[ -f "${magento1ConfigFile}" ]]; then
      magento1ConfigPath=$(dirname "${magento1ConfigFile}")
      configFile="${magento1ConfigPath}/local.redis-fpc.xml"
      echo "Creating configuration file: ${configFile}"
      cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <full_page_cache>
            <id_prefix><![CDATA[${redisFPCCachePrefix}]]></id_prefix>
            <backend>${redisFPCClassName}</backend>
            <backend_options>
                <server>${redisFPCHost}</server>
                <port>${redisFPCPort}</port>
                <database>${redisFPCDatabase}</database>
                <password>${redisFPCPassword}</password>
                <persistent/>
                <force_standalone>0</force_standalone>
                <connect_retries>1</connect_retries>
                <lifetimelimit>57600</lifetimelimit>
                <compress_data>0</compress_data>
            </backend_options>
        </full_page_cache>
    </global>
</config>
EOF

      "${mergeScript}" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -m "${mergeScriptPhpScript}"
    fi
  fi
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  magento2ConfigFile="${webPath}/app/etc/env.php"

  if [[ -L "${magento2ConfigFile}" ]]; then
    magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
  fi

  if [[ -f "${magento2ConfigFile}" ]]; then
    magento2ConfigPath=$(dirname "${magento2ConfigFile}")
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/id_prefix" "${redisFPCCachePrefix}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend" "${redisFPCClassName}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/server" "${redisFPCHost}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/port" "${redisFPCPort}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/database" "${redisFPCDatabase}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/password" "${redisFPCPassword}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/persistent" ""
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/force_standalone" "0"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/connect_retries" "1"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/lifetimelimit" "57600"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/compress_data" "0"
  fi
fi

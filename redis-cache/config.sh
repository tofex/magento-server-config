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
  --redisCacheHost         Redis cache host
  --redisCachePort         Redis cache port
  --redisCachePassword     Redis cache password (optional)
  --redisCacheDatabase     Redis cache database
  --redisCacheCachePrefix  Redis cache prefix, default: cache_
  --redisCacheClassName    Redis cache class name, default: Cm_Cache_Backend_Redis
  --webPath                Web path
  --webUser                Web user
  --webGroup               Web group
  --mergeScript            Merge script (required if Magento 1)
  --mergeScriptPhpScript   Merge script PHP script (required if Magento 1)
  --addScript              Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.3.7 --redisCacheHost localhost --redisCachePort 6379 --redisCacheDatabase 0 --addScript /tmp/add.php
EOF
}

magentoVersion=
redisCacheHost=
redisCachePort=
redisCachePassword=
redisCacheDatabase=
redisCacheCachePrefix=
redisCacheClassName=
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

if [[ -z "${redisCacheHost}" ]]; then
  echo "No Redis cache host specified!"
  usage
  exit 1
fi

if [[ -z "${redisCachePort}" ]]; then
  echo "No Redis cache port specified!"
  usage
  exit 1
fi

if [[ -z "${redisCacheDatabase}" ]]; then
  echo "No Redis cache database specified!"
  usage
  exit 1
fi

if [[ -z "${redisCacheCachePrefix}" ]]; then
  redisCacheCachePrefix="cache_"
fi

if [[ -z "${redisCacheClassName}" ]]; then
  redisCacheClassName="Cm_Cache_Backend_Redis"
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
      configFile="${magento1ConfigPath}/local.redis-cache.xml"
      echo "Creating configuration file: ${configFile}"
      cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <cache>
            <id_prefix><![CDATA[${redisCacheCachePrefix}]]></id_prefix>
            <backend>${redisCacheClassName}</backend>
            <backend_options>
                <server>${redisCacheHost}</server>
                <port>${redisCachePort}</port>
                <database>${redisCacheDatabase}</database>
                <password>${redisCachePassword}</password>
                <persistent/>
                <force_standalone>0</force_standalone>
                <connect_retries>2</connect_retries>
                <read_timeout>10</read_timeout>
                <automatic_cleaning_factor>0</automatic_cleaning_factor>
                <compress_data>1</compress_data>
                <compress_tags>1</compress_tags>
                <compress_threshold>20480</compress_threshold>
                <compression_lib>gzip</compression_lib>
                <use_lua>0</use_lua>
            </backend_options>
            <lifetime>1296000</lifetime>
        </cache>
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
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/id_prefix" "${redisCacheCachePrefix}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend" "${redisCacheClassName}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/server" "${redisCacheHost}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/port" "${redisCachePort}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/database" "${redisCacheDatabase}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/password" "${redisCachePassword}"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/persistent" ""
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/force_standalone" "0"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/connect_retries" "2"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/read_timeout" "10"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/automatic_cleaning_factor" "0"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_data" "1"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_tags" "1"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_threshold" "20480"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compression_lib" "gzip"
    php "${addScript}" "${magento2ConfigPath}" "cache/frontend/default/backend_options/use_lua" "0"
  fi
fi

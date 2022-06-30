#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                     Show this message
  --magentoVersion           Magento version
  --redisSessionHost         Redis session host
  --redisSessionPort         Redis session port
  --redisSessionPassword     Redis session password (optional)
  --redisSessionDatabase     Redis session database
  --webPath                  Web path
  --webUser                  Web user
  --webGroup                 Web group
  --mergeScript              Merge script (required if Magento 1)
  --mergeScriptPhpScript     Merge script PHP script (required if Magento 1)
  --addScript                Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.3.7 --redisSessionHost localhost --redisSessionPort 6379 --redisSessionDatabase 0 --addScript /tmp/add.php
EOF
}

magentoVersion=
redisSessionHost=
redisSessionPort=
redisSessionPassword=
redisSessionDatabase=
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

if [[ -z "${redisSessionHost}" ]]; then
  echo "No Redis session host specified!"
  usage
  exit 1
fi

if [[ -z "${redisSessionPort}" ]]; then
  echo "No Redis session port specified!"
  usage
  exit 1
fi

if [[ -z "${redisSessionDatabase}" ]]; then
  echo "No Redis session database specified!"
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
          configFile="${magento1ConfigPath}/local.redis-session.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <session_save><![CDATA[db]]></session_save>
        <redis_session>
            <host>${redisSessionHost}</host>
            <port>${redisSessionPort}</port>
            <db>${redisSessionDatabase}</db>
            <password>${redisSessionPassword}</password>
            <persistent/>
            <timeout>2.5</timeout>
            <compression_threshold>2048</compression_threshold>
            <compression_lib>gzip</compression_lib>
            <log_level>1</log_level>
            <max_concurrency>60</max_concurrency>
            <break_after_frontend>5</break_after_frontend>
            <fail_after>10</fail_after>
            <break_after_adminhtml>30</break_after_adminhtml>
            <first_lifetime>600</first_lifetime>
            <bot_first_lifetime>60</bot_first_lifetime>
            <bot_lifetime>7200</bot_lifetime>
            <disable_locking>0</disable_locking>
            <min_lifetime>60</min_lifetime>
            <max_lifetime>2592000</max_lifetime>
        </redis_session>
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
    php "${addScript}" "${magento2ConfigPath}" "session/save" "redis"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/host" "${redisSessionHost}"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/port" "${redisSessionPort}"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/database" "${redisSessionDatabase}"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/password" "${redisSessionPassword}"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/persistent_identifier" ""
    php "${addScript}" "${magento2ConfigPath}" "session/redis/timeout" "2.5"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/compression_threshold" "2048"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/compression_library" "gzip"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/log_level" "1"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/max_concurrency" "6"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/break_after_frontend" "5"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/break_after_adminhtml" "30"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/fail_after" "10"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/first_lifetime" "600"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/bot_first_lifetime" "60"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/bot_lifetime" "7200"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/disable_locking" "0"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/min_lifetime" "60"
    php "${addScript}" "${magento2ConfigPath}" "session/redis/max_lifetime" "2592000"
  fi
fi

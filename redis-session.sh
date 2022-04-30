#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

redisSession=
redisSessionHost=
for server in "${serverList[@]}"; do
  redisSession=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisSession")
  if [[ -n "${redisSession}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      redisSessionHost="localhost"
    else
      redisSessionHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${redisSessionHost}" ]]; then
  echo "No Redis session settings found"
  exit 1
fi

port=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisSession}" "port")
database=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisSession}" "database")
password=$(ini-parse "${currentPath}/../env.properties" "no" "${redisSession}" "password")

if [[ -z "${port}" ]]; then
  echo "No Redis cache port specified!"
  exit 1
fi

if [[ -z "${database}" ]]; then
  echo "No Redis cache database specified!"
  exit 1
fi

merge=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Configuring Redis session on server: ${server} ---"

      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          merge=1
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
            <port>${port}</port>
            <db>${database}</db>
            <password>${password}</password>
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
        else
          echo "Magento config file not found"
        fi
      else
        echo "Magento config file not found"
      fi

      # Magento 2
      magento2ConfigFile="${webPath}/app/etc/env.php"
      if [[ -e "${magento2ConfigFile}" ]]; then
        if [[ -L "${magento2ConfigFile}" ]]; then
          magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
        fi
        if [[ -f "${magento2ConfigFile}" ]]; then
          magento2ConfigPath=$(dirname "${magento2ConfigFile}")
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/save" "redis"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/host" "${redisSessionHost}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/port" "${port}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/database" "${database}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/password" "${password}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/persistent_identifier" ""
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/timeout" "2.5"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/compression_threshold" "2048"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/compression_library" "gzip"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/log_level" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/max_concurrency" "6"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/break_after_frontend" "5"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/break_after_adminhtml" "30"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/fail_after" "10"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/first_lifetime" "600"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/bot_first_lifetime" "60"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/bot_lifetime" "7200"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/disable_locking" "0"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/min_lifetime" "60"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "session/redis/max_lifetime" "2592000"
        fi
      fi
    fi
  fi
done

if [[ "${merge}" == 1 ]]; then
  "${currentPath}/merge.sh"
fi

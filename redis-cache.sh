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

redisCache=
redisCacheHost=
for server in "${serverList[@]}"; do
  redisCache=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisCache")
  if [[ -n "${redisCache}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      redisCacheHost="localhost"
    else
      redisCacheHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${redisCacheHost}" ]]; then
  echo "No Redis cache settings found"
  exit 1
fi

port=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisCache}" "port")
database=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisCache}" "database")
className=$(ini-parse "${currentPath}/../env.properties" "no" "${redisCache}" "className")
password=$(ini-parse "${currentPath}/../env.properties" "no" "${redisCache}" "password")
prefix=$(ini-parse "${currentPath}/../env.properties" "no" "${redisCache}" "prefix")

if [[ -z "${port}" ]]; then
  echo "No Redis cache port specified!"
  exit 1
fi

if [[ -z "${database}" ]]; then
  echo "No Redis cache database specified!"
  exit 1
fi

if [[ -z "${className}" ]]; then
  className="Cm_Cache_Backend_Redis"
fi

if [[ -z "${prefix}" ]]; then
  prefix="cache_"
fi

merge=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Configuring Redis cache on local server: ${server} ---"

      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          merge=1
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.redis-cache.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <cache>
            <id_prefix><![CDATA[${prefix}]]></id_prefix>
            <backend>${className}</backend>
            <backend_options>
                <server>${redisCacheHost}</server>
                <port>${port}</port>
                <database>${database}</database>
                <password>${password}</password>
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
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/id_prefix" "${prefix}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend" "${className}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/server" "${redisCacheHost}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/port" "${port}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/database" "${database}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/password" "${password}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/persistent" ""
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/force_standalone" "0"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/connect_retries" "2"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/read_timeout" "10"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/automatic_cleaning_factor" "0"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_data" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_tags" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compress_threshold" "20480"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/compression_lib" "gzip"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/default/backend_options/use_lua" "0"
        fi
      fi
    fi
  fi
done

if [[ "${merge}" == 1 ]]; then
  "${currentPath}/merge.sh"
fi

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

redisFPC=
redisFPCHost=
for server in "${serverList[@]}"; do
  redisFPC=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisFPC")
  if [[ -n "${redisFPC}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      redisFPCHost="localhost"
    else
      redisFPCHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${redisFPCHost}" ]]; then
  echo "No Redis full page cache settings found"
  exit 1
fi

port=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisFPC}" "port")
database=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisFPC}" "database")
className=$(ini-parse "${currentPath}/../env.properties" "no" "${redisFPC}" "className")
password=$(ini-parse "${currentPath}/../env.properties" "no" "${redisFPC}" "password")
prefix=$(ini-parse "${currentPath}/../env.properties" "no" "${redisFPC}" "prefix")

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
      echo "--- Configuring Redis FPC on server: ${server} ---"

      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          merge=1
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.redis-fpc.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <full_page_cache>
            <id_prefix><![CDATA[${prefix}]]></id_prefix>
            <backend>${className}</backend>
            <backend_options>
                <server>${redisFPCHost}</server>
                <port>${port}</port>
                <database>${database}</database>
                <password>${password}</password>
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
        fi
      fi

      # Magento 2
      magento2ConfigFile="${webPath}/app/etc/env.php"
      if [[ -e "${magento2ConfigFile}" ]]; then
        if [[ -L "${magento2ConfigFile}" ]]; then
          magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
        fi
        if [[ -f "${magento2ConfigFile}" ]]; then
          magento2ConfigPath=$(dirname "${magento2ConfigFile}")
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/id_prefix" "${prefix}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend" "${className}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/server" "${redisFPCHost}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/port" "${port}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/database" "${database}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/password" "${password}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/persistent" ""
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/force_standalone" "0"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/connect_retries" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/lifetimelimit" "57600"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "cache/frontend/page_cache/backend_options/compress_data" "0"
        fi
      fi
    fi
  fi
done

if [[ "${merge}" == 1 ]]; then
  "${currentPath}/merge.sh"
fi

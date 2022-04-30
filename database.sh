#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

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

database=
databaseHost=
for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      databaseHost="localhost"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${databaseHost}" ]]; then
  echo "No database settings found"
  exit 1
fi

databasePort=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

merge=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      currentUser="$(whoami)"
      if [[ -z "${webUser}" ]]; then
        webUser="${currentUser}"
      fi
      currentGroup="$(id -g -n)"
      if [[ -z "${webGroup}" ]]; then
        webGroup="${currentGroup}"
      fi
      echo "--- Configuring database on local server: ${server} ---"

      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          merge=1
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.database.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <resources>
            <default_setup>
                <connection>
                    <host><![CDATA[${databaseHost}]]></host>
                    <username><![CDATA[${databaseUser}]]></username>
                    <password><![CDATA[${databasePassword}]]></password>
                    <dbname><![CDATA[${databaseName}]]></dbname>
                    <model><![CDATA[mysql4]]></model>
                    <type><![CDATA[pdo_mysql]]></type>
                    <pdoType><![CDATA[]]></pdoType>
                    <initStatements><![CDATA[SET NAMES utf8;]]></initStatements>
                    <active>1</active>
                </connection>
            </default_setup>
        </resources>
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
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/table_prefix\" \"\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/host\" \"${databaseHost}\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/username\" \"${databaseUser}\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/password\" \"${databasePassword}\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/dbname\" \"${databaseName}\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/model\" \"mysql4\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/engine\" \"innodb\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/initStatements\" \"SET NAMES utf8;\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/active\" \"1\""
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"resource/default_setup/connection\" \"default\""
          else
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/table_prefix" ""
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/host" "${databaseHost}"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/username" "${databaseUser}"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/password" "${databasePassword}"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/dbname" "${databaseName}"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/model" "mysql4"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/engine" "innodb"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/initStatements" "SET NAMES utf8;"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/active" "1"
            php "${currentPath}/add.php" "${magento2ConfigPath}" "resource/default_setup/connection" "default"
          fi
        fi
      fi
    fi
  fi
done

if [[ "${merge}" == 1 ]]; then
  "${currentPath}/merge.sh"
fi

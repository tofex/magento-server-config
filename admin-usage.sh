#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -e  Enable admin usage
  -d  Disable admin usage

Example: ${scriptName} -e
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

enable=0
disable=0

while getopts hed? option; do
  case "${option}" in
    h) usage; exit 1;;
    e) enable=1;;
    d) disable=1;;
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
      echo "--- Configuring admin usage on local server: ${server} ---"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      echo "--- Configuring admin usage on remote server: ${server} ---"
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

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

export MYSQL_PWD="${databasePassword}"

if [[ $(versionCompare "${magentoVersion}" "2.3.3") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.3.3") == 2 ]]; then
  echo "Delete previous admin usage settings"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/usage/enabled';"
  if [[ "${enable}" == 1 ]]; then
    echo "Enable admin usage"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/usage/enabled', 1);"
  fi
  if [[ "${disable}" == 1 ]]; then
    echo "Disable admin usage"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/usage/enabled', 0);"
  fi
  tableExists=$(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${databaseName}' AND table_name='admin_analytics_usage_version_log';")
  if [[ "${tableExists}" == 1 ]]; then
    echo "Adding version log"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_analytics_usage_version_log (last_viewed_in_version) VALUES ('${magentoVersion}');"
  else
    echo "No version log table found"
  fi
fi

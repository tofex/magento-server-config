#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --databaseHost      Database host
  --databasePort      Database port
  --databaseUser      Name of the database user
  --databasePassword  Password of the database user
  --databaseName      Name of the database

Example: ${scriptName} --databaseHost localhost --databasePort 3306 --databaseUser magento --databasePassword magento --databaseName magento
EOF
}

databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  usage
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  usage
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  usage
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  usage
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  usage
  exit 1
fi

export MYSQL_PWD="${databasePassword}"

echo "Removing database configuration"

mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/general/enabled';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/host';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/port';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/protocol';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/authentication';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/username';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'smtp/configuration_option/password';"

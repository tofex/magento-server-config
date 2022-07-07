#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --databaseHost      Database host, default: localhost
  --databasePort      Database port, default: 3306
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
read=0
removed=0

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort=3306
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

if [[ "${read}" == 1 ]]; then
  echo "Marking all notifications as read"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE adminnotification_inbox SET is_read=1;"
fi
if [[ "${removed}" == 1 ]]; then
  echo "Marking all notifications as removed"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE adminnotification_inbox SET is_remove=1;"
fi

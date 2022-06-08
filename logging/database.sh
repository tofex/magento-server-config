#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database

Example: ${scriptName} -m 2.3.7 -u magento -p magento -b magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
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

if [[ ${magentoVersion:0:1} == 1 ]]; then
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = 1 WHERE path = 'dev/log/active';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = 'system.log' WHERE path = 'dev/log/file';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = 'exception.log' WHERE path = 'dev/log/exception_file';"
fi

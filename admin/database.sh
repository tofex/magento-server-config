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
  -a  Admin path, default: admin

Example: ${scriptName} -m 2.3.7 -u magento -p magento -b magento -a custompath
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
adminPath=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:a:? option; do
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
    a) adminPath=$(trim "$OPTARG");;
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

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

export MYSQL_PWD="${databasePassword}"

# Magento 1
if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "Deleting previous entries in database"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom_path';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom_path';"

  if [[ "${adminPath}" != "admin" ]]; then
    echo "Adding custom path settings"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/use_custom', '1');"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/use_custom_path', '${adminPath}');"
  fi
fi

# Magento 2
if [[ ${magentoVersion:0:1} == 2 ]]; then
  echo "Deleting previous entries in database"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom_path';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom_path';"
fi

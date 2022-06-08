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
  -a  Enable admin usage
  -i  Disable admin usage

Example: ${scriptName} -m 2.3.7 -u magento -p magento -b magento
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

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
enable=0
disable=0

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:ai? option; do
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
    a) enable=1;;
    i) disable=1;;
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

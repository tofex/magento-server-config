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
  --prefix            Prefix to use

Example: ${scriptName} --databaseUser magento --databasePassword magento --databaseName magento --prefix 12345
EOF
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
prefix=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
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

if [[ -z "${prefix}" ]]; then
  echo "No prefix specified!"
  usage
  exit 1
fi

export MYSQL_PWD="${databasePassword}"

echo "Update prefixes in database with: ${prefix}"

mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE eav_entity_store SET increment_prefix = CONCAT(store_id, \"${prefix}\");"

if [[ $(versionCompare "${magentoVersion}" "2.3.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.3.0") == 2 ]]; then
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE sales_sequence_profile JOIN sales_sequence_meta ON sales_sequence_meta.meta_id = sales_sequence_profile.meta_id SET prefix = CONCAT(store_id, \"${prefix}\");"
fi

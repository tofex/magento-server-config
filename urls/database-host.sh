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

Example: ${scriptName} -m 1.9.4.5 -u magento -p magento -b magento
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
serverName=
scope=
code=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:x:y:z:? option; do
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
    x) serverName=$(trim "$OPTARG");;
    y) scope=$(trim "$OPTARG");;
    z) code=$(trim "$OPTARG");;
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

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  usage
  exit 1
fi

if [[ -z "${scope}" ]]; then
  echo "No scope specified!"
  usage
  exit 1
fi

if [[ -z "${code}" ]]; then
  echo "No code specified!"
  usage
  exit 1
fi

export MYSQL_PWD="${databasePassword}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  if [[ "${scope}" == "website" ]]; then
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${serverName}/' FROM core_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${serverName}/' FROM core_website WHERE code = '$code}'"
  elif [[ "${scope}" == "store" ]]; then
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${serverName}/' FROM core_store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${serverName}/' FROM core_store WHERE code = '${code}'"
  fi
else
  if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.2.0") == 2 ]]; then
    secureBaseMediaUrl="{{secure_base_url}}media/"
    secureBaseStaticUrl="{{secure_base_url}}static/"
    unsecureBaseMediaUrl="{{unsecure_base_url}}media/"
    unsecureBaseStaticUrl="{{unsecure_base_url}}static/"
  else
    secureBaseMediaUrl="{{secure_base_url}}pub/media/"
    secureBaseStaticUrl="{{secure_base_url}}pub/static/"
    unsecureBaseMediaUrl="{{unsecure_base_url}}pub/media/"
    unsecureBaseStaticUrl="{{unsecure_base_url}}pub/static/"
  fi

  if [[ "${scope}" == "website" ]]; then
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${serverName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${serverName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_link_url', 'https://${serverName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_link_url', 'https://${serverName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_media_url', '${secureBaseMediaUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_media_url', '${unsecureBaseMediaUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_static_url', '${secureBaseStaticUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_static_url', '${unsecureBaseStaticUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/cookie/cookie_domain', 'https://${serverName}/' FROM store_website WHERE code = '${code}'"
  elif [[ "${scope}" == "store" ]]; then
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${serverName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${serverName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_link_url', 'https://${serverName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_link_url', 'https://${serverName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_media_url', '${secureBaseMediaUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_media_url', '${unsecureBaseMediaUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_static_url', '${secureBaseStaticUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_static_url', '${unsecureBaseStaticUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/cookie/cookie_domain', 'https://${serverName}/' FROM store WHERE code = '${code}'"
  fi
fi

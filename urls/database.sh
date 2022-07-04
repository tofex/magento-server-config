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
  -a  Main host name

Example: ${scriptName} -m 1.9.4.5 -u magento -p magento -b magento -a dev.magento2.de
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
mainHostName=

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
    a) mainHostName=$(trim "$OPTARG");;
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

if [[ -z "${mainHostName}" ]]; then
  echo "No main host name specified!"
  usage
  exit 1
fi

export MYSQL_PWD="${databasePassword}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/secure/base_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/unsecure/base_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/cookie/cookie_domain';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/cookie/cookie_path';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{secure_base_url}}' WHERE path = 'web/secure/base_link_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{unsecure_base_url}}' WHERE path = 'web/unsecure/base_link_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{secure_base_url}}skin/' WHERE path = 'web/secure/base_skin_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{unsecure_base_url}}skin/' WHERE path = 'web/unsecure/base_skin_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{secure_base_url}}media/' WHERE path = 'web/secure/base_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{unsecure_base_url}}media/' WHERE path = 'web/unsecure/base_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{secure_base_url}}media/' WHERE path = 'web/secure/base_static_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{unsecure_base_url}}media/' WHERE path = 'web/unsecure/base_static_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{secure_base_url}}js/' WHERE path = 'web/secure/base_js_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE core_config_data SET value = '{{unsecure_base_url}}js/' WHERE path = 'web/unsecure/base_js_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_url', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_url', 'https://${mainHostName}/');"
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

  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/secure/base_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/unsecure/base_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/secure/base_link_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/unsecure/base_link_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/secure/base_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/unsecure/base_media_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/secure/base_static_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/unsecure/base_static_url';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/cookie/cookie_domain'";
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'web/cookie/cookie_path';"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_url', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_url', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_link_url', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_link_url', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_media_url', '${secureBaseMediaUrl}');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_media_url', '${unsecureBaseMediaUrl}');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_static_url', '${secureBaseStaticUrl}');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_static_url', '${unsecureBaseStaticUrl}');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/cookie/cookie_domain', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/cookie/cookie_path', '/');"
fi
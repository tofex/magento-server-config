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
      echo "--- Configuring urls on local server: ${server} ---"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      echo "--- Configuring urls on remote server: ${server} ---"
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

hostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

mainHostName=
for host in "${hostList[@]}"; do
  vhostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "vhost") )
  if [[ "${#hostList[@]}" -eq 0 ]]; then
    echo "No hosts specified!"
    exit 1
  fi
  mainHostName="${vhostList[0]}"
  break
done

if [[ -z "${mainHostName}" ]]; then
  echo "No main host found!"
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

  for host in "${hostList[@]}"; do
    vhostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "vhost") )
    scope=$(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "scope")
    code=$(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "code")
    hostName="${vhostList[0]}"

    if [[ "${scope}" == "website" ]]; then
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${hostName}/' FROM core_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${hostName}/' FROM core_website WHERE code = '$code}'"
    elif [[ "${scope}" == "store" ]]; then
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${hostName}/' FROM core_store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${hostName}/' FROM core_store WHERE code = '${code}'"
    fi
  done
else
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
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_media_url', '{{secure_base_url}}media/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_media_url', '{{unsecure_base_url}}media/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/secure/base_static_url', '{{secure_base_url}}static/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/unsecure/base_static_url', '{{unsecure_base_url}}static/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/cookie/cookie_domain', 'https://${mainHostName}/');"
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'web/cookie/cookie_path', '/');"

  for host in "${hostList[@]}"; do
    vhostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "vhost") )
    scope=$(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "scope")
    code=$(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "code")
    hostName="${vhostList[0]}"

    if [[ "${scope}" == "website" ]]; then
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${hostName}/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${hostName}/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_link_url', 'https://${hostName}/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_link_url', 'https://${hostName}/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_media_url', '{{secure_base_url}}media/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_media_url', '{{unsecure_base_url}}media/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_static_url', '{{secure_base_url}}static/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_static_url', '{{unsecure_base_url}}static/' FROM store_website WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/cookie/cookie_domain', 'https://${hostName}/' FROM store_website WHERE code = '${code}'"
    elif [[ "${scope}" == "store" ]]; then
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${hostName}/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${hostName}/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_link_url', 'https://${hostName}/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_link_url', 'https://${hostName}/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_media_url', '{{secure_base_url}}media/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_media_url', '{{unsecure_base_url}}media/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_static_url', '{{secure_base_url}}static/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_static_url', '{{unsecure_base_url}}static/' FROM store WHERE code = '${code}'"
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/cookie/cookie_domain', 'https://${hostName}/' FROM store WHERE code = '${code}'"
    fi
  done
fi

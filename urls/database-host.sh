#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --magentoVersion     Magento version
  --documentRootIsPub  Flag if pub folder is root directory (yes/no), default: yes
  --databaseHost       Database host
  --databasePort       Database port
  --databaseUser       Name of the database user
  --databasePassword   Password of the database user
  --databaseName       Name of the database
  --hostServerName     Server name of the host
  --scope              Scope of host (default, website, store)
  --code               Code of scope

Example: ${scriptName} --magentoVersion 1.9.4.5 --databaseUser magento --databasePassword magento --databaseName magento --hostServerName dev.magento.de --scope website --code base
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
documentRootIsPub=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
hostServerName=
scope=
code=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${documentRootIsPub}" ]]; then
  documentRootIsPub="yes"
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

if [[ -z "${hostServerName}" ]]; then
  echo "No host server name specified!"
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
    echo "Setting base url of website with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${hostServerName}/' FROM core_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${hostServerName}/' FROM core_website WHERE code = '$code}'"
  elif [[ "${scope}" == "store" ]]; then
    echo "Setting base url of store with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${hostServerName}/' FROM core_store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${hostServerName}/' FROM core_store WHERE code = '${code}'"
  fi
else
  if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.2.0") == 2 ]]; then
    if [[ "${documentRootIsPub}" == "yes" ]]; then
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
  else
    secureBaseMediaUrl="{{secure_base_url}}pub/media/"
    secureBaseStaticUrl="{{secure_base_url}}pub/static/"
    unsecureBaseMediaUrl="{{unsecure_base_url}}pub/media/"
    unsecureBaseStaticUrl="{{unsecure_base_url}}pub/static/"
  fi

  if [[ "${scope}" == "website" ]]; then
    echo "Setting base url of website with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_url', 'https://${hostServerName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_url', 'https://${hostServerName}/' FROM store_website WHERE code = '${code}'"

    echo "Setting base link url of website with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_link_url', 'https://${hostServerName}/' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_link_url', 'https://${hostServerName}/' FROM store_website WHERE code = '${code}'"

    echo "Setting base media url of website with code: ${code} to: ${secureBaseMediaUrl}"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_media_url', '${secureBaseMediaUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_media_url', '${unsecureBaseMediaUrl}' FROM store_website WHERE code = '${code}'"

    echo "Setting base static url of website with code: ${code} to: ${secureBaseMediaUrl}"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/secure/base_static_url', '${secureBaseStaticUrl}' FROM store_website WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/unsecure/base_static_url', '${unsecureBaseStaticUrl}' FROM store_website WHERE code = '${code}'"

    echo "Setting cookie domain of website with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/cookie/cookie_domain', 'https://${hostServerName}/' FROM store_website WHERE code = '${code}'"

    echo "Setting cookie path of website with code: ${code} to: /"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'websites', website_id, 'web/cookie/cookie_path', '/' FROM store_website WHERE code = '${code}'"
  elif [[ "${scope}" == "store" ]]; then
    echo "Setting base url of store with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_url', 'https://${hostServerName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_url', 'https://${hostServerName}/' FROM store WHERE code = '${code}'"

    echo "Setting base link url of store with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_link_url', 'https://${hostServerName}/' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_link_url', 'https://${hostServerName}/' FROM store WHERE code = '${code}'"

    echo "Setting base media url of store with code: ${code} to: ${secureBaseMediaUrl}"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_media_url', '${secureBaseMediaUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_media_url', '${unsecureBaseMediaUrl}' FROM store WHERE code = '${code}'"

    echo "Setting base static url of store with code: ${code} to: ${secureBaseMediaUrl}"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/secure/base_static_url', '${secureBaseStaticUrl}' FROM store WHERE code = '${code}'"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/unsecure/base_static_url', '${unsecureBaseStaticUrl}' FROM store WHERE code = '${code}'"

    echo "Setting cookie domain of store with code: ${code} to: https://${hostServerName}/"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/cookie/cookie_domain', 'https://${hostServerName}/' FROM store WHERE code = '${code}'"

    echo "Setting cookie path of store with code: ${code} to: /"
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "INSERT INTO core_config_data (scope, scope_id, path, value) SELECT 'stores', store_id, 'web/cookie/cookie_path', '/' FROM store WHERE code = '${code}'"
  fi
fi

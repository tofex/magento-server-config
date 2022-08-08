#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -b  Business account
  -u  API user name
  -p  API password
  -s  API signature
  -m  Merchant account id

Example: ${scriptName} -f
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

echo "Removing database configuration"
export MYSQL_PWD="${databasePassword}"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'payment/paypal_standard/active';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'payment/paypal_wps_express/active';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'payment/paypal_express/active';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'payment/paypal_express/debug';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'payment/paypal_express/merchant_id';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/general/business_account';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/general/merchant_country';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/wpp/api_password';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/wpp/api_signature';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/wpp/api_username';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'paypal/wpp/sandbox_flag';"

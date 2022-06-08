#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database

Example: ${scriptName} -u magento -p magento -b magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=

while getopts ho:p:u:s:b:t:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
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

echo "Removing database configuration"

mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'contact/email/recipient_email';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/creditmemo_comment/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/creditmemo/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/invoice_comment/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/invoice/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/order_comment/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'ales_email/order/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/shipment_comment/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'sales_email/shipment/copy_to';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'trans_email/ident_custom1/email';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'trans_email/ident_custom2/email';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'trans_email/ident_general/email';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'trans_email/ident_sales/email';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'trans_email/ident_support/email';"

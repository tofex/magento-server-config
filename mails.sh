#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Mail address, default: webmaster@localhost.local

Example: ${scriptName} -m webmaster@localhost.local
EOF
}

trim()
{
  echo -n "$1" | xargs
}

mailAddress=

while getopts hm:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) mailAddress=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

mailAddress=$(ini-parse "${currentPath}/../env.properties" "no" "install" "mailAddress")
if [[ -z "${mailAddress}" ]]; then
  mailAddress="webmaster@localhost.local"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

database=
databaseHost=
databaseServerName=
for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      databaseHost="localhost"
      databaseServerName="${server}"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      databaseServerName="${server}"
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

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Configuring mail addresses on server: ${server} ---"
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      magento2ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.mails.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <default>
        <contacts>
            <email>
                <recipient_email><![CDATA[${mailAddress}]]></recipient_email>
            </email>
        </contacts>
        <sales_email>
            <order>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </order>
            <invoice>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </invoice>
            <shipment>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </shipment>
            <creditmemo>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </creditmemo>
            <notification>
                <emails><![CDATA[${mailAddress}]]></emails>
            </notification>
        </sales_email>
        <system>
            <cron>
                <error_email><![CDATA[${mailAddress}]]></error_email>
            </cron>
            <log>
                <error_email><![CDATA[${mailAddress}]]></error_email>
            </log>
        </system>
        <trans_email>
            <ident_general>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_general>
            <ident_sales>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_sales>
            <ident_support>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_support>
            <ident_custom1>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_custom1>
            <ident_custom2>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_custom2>
        </trans_email>
    </default>
</config>
EOF
          "${currentPath}/merge.sh"
        fi
      fi

      magento2ConfigFile="${webPath}/app/etc/env.php"
      if [[ -e "${magento2ConfigFile}" ]]; then
        if [[ -L "${magento2ConfigFile}" ]]; then
          magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
        fi
        if [[ -f "${magento2ConfigFile}" ]]; then
          magento2ConfigPath=$(dirname "${magento2ConfigFile}")
          php "${currentPath}/add.php" "${magento2ConfigPath}" "contact/email/recipient_email" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/creditmemo_comment/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/creditmemo/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/invoice_comment/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/invoice/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/order_comment/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/order/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/shipment_comment/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "sales_email/shipment/copy_to" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "trans_email/ident_custom1/email" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "trans_email/ident_custom2/email" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "trans_email/ident_general/email" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "trans_email/ident_sales/email" "${mailAddress}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "trans_email/ident_support/email" "${mailAddress}"
        fi
      fi
    fi
  fi
done

cat <<EOF | tee "/tmp/config-mails.sh" > /dev/null
#!/bin/bash -e
echo "Removing database configuration"
export MYSQL_PWD="${databasePassword}"
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
EOF

chmod +x /tmp/config-mails.sh

serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "type")

echo "--- Updating mail addresses on database server: ${server} ---"
if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "docker" ]]; then
  /tmp/config-mails.sh
elif [[ "${serverType}" == "ssh" ]]; then
  user=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "user")
  echo "Copying script to ${user}@${databaseHost}:/tmp/config-mails.sh"
  scp -q "/tmp/config-mails.sh" "${user}@${databaseHost}:/tmp/config-mails.sh"
  ssh "${user}@${databaseHost}" "/tmp/config-mails.sh"
  ssh "${user}@${databaseHost}" "rm -rf /tmp/config-mails.sh"
else
  echo "Invalid database server type: ${serverType}"
  exit 1
fi

rm -rf /tmp/config-mails.sh

#!/bin/bash -e

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

trim()
{
  echo -n "$1" | xargs
}

businessAccount=""
apiUserName=""
apiPassword=""
apiSignature=""
merchantAccountId=""

while getopts hb:u:p:s:m:? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) businessAccount=$(trim "$OPTARG");;
    u) apiUserName=$(trim "$OPTARG");;
    p) apiPassword=$(trim "$OPTARG");;
    s) apiSignature=$(trim "$OPTARG");;
    m) merchantAccountId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${businessAccount}" ]] && [[ -z "${apiUserName}" ]] && [[ -z "${apiPassword}" ]] && [[ -z "${apiSignature}" ]] && [[ -z "${merchantAccountId}" ]]; then
  businessAccount="development@tofex.de"
  apiUserName="development_api1.tofex.de"
  apiPassword="CDE6PD9LJ2Y2FY43"
  apiSignature="AFcWxV21C7fd0v3bYYYRCpSSRl31A3gMBpif1IPuWzAnR5VZiWNiT-iB"
  merchantAccountId="XHX9XT49M35DQ"
fi

if [[ -z "${businessAccount}" ]]; then
  echo "No business account defined!"
  exit 1
fi

if [[ -z "${apiUserName}" ]]; then
  echo "No API user name defined!"
  exit 1
fi

if [[ -z "${apiPassword}" ]]; then
  echo "No API user password defined!"
  exit 1
fi

if [[ -z "${apiSignature}" ]]; then
  echo "No API signature defined!"
  exit 1
fi

if [[ -z "${merchantAccountId}" ]]; then
  echo "No merchant account id defined!"
  exit 1
fi

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
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
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
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Configuring Paypal payment on local server: ${server} ---"
      currentUser="$(whoami)"
      if [[ -z "${webUser}" ]]; then
        webUser="${currentUser}"
      fi
      currentGroup="$(id -g -n)"
      if [[ -z "${webGroup}" ]]; then
        webGroup="${currentGroup}"
      fi
      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          cd "${webPath}"
          encryptScript="shell/encrypt.php";
          if [[ -f "${encryptScript}" ]]; then
            if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
              apiUserName=$(sudo -H -u "${webUser}" bash -c "php ${encryptScript} --value \"${apiUserName}\"")
              apiPassword=$(sudo -H -u "${webUser}" bash -c "php ${encryptScript} --value \"${apiPassword}\"")
              apiSignature=$(sudo -H -u "${webUser}" bash -c "php ${encryptScript} --value \"${apiSignature}\"")
            else
              apiUserName=$(php "${encryptScript}" --value "${apiUserName}")
              apiPassword=$(php "${encryptScript}" --value "${apiPassword}")
              apiSignature=$(php "${encryptScript}" --value "${apiSignature}")
            fi
          fi
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.paypal.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version='1.0' encoding="utf-8" ?>
<config>
    <default>
        <payment>
            <paypal_standard>
                <active>0</active>
            </paypal_standard>
            <paypal_wps_express>
                <active>0</active>
            </paypal_wps_express>
            <paypal_express>
                <active>1</active>
                <debug>1</debug>
            </paypal_express>
        </payment>
        <paypal>
            <general>
                <business_account><![CDATA[${businessAccount}]]></business_account>
            </general>
            <wpp>
                <api_password backend_model="adminhtml/system_config_backend_encrypted"><![CDATA[${apiPassword}]]></api_password>
                <api_signature backend_model="adminhtml/system_config_backend_encrypted"><![CDATA[${apiSignature}]]></api_signature>
                <api_username backend_model="adminhtml/system_config_backend_encrypted"><![CDATA[${apiUserName}]]></api_username>
                <sandbox_flag>1</sandbox_flag>
            </wpp>
        </paypal>
    </default>
</config>
EOF
          "${currentPath}/merge.sh"
        fi
      fi
      # Magento 2
      magento2ConfigFile="${webPath}/app/etc/config.php"
      if [[ -e "${magento2ConfigFile}" ]]; then
        if [[ -L "${magento2ConfigFile}" ]]; then
          magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
        fi
        if [[ -f "${magento2ConfigFile}" ]]; then
          cd "${webPath}"
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            if [[ $(sudo -H -u "${webUser}" bash -c "bin/magento" | grep "encryption:encrypt" | wc -l) -eq 1 ]]; then
              apiUserName=$(sudo -H -u "${webUser}" bash -c "bin/magento encryption:encrypt --value \"${apiUserName}\"")
              apiPassword=$(sudo -H -u "${webUser}" bash -c "bin/magento encryption:encrypt --value \"${apiPassword}\"")
              apiSignature=$(sudo -H -u "${webUser}" bash -c "bin/magento encryption:encrypt --value \"${apiSignature}\"")
            fi
          else
            if [[ $(bin/magento | grep "encryption:encrypt" | wc -l) -eq 1 ]]; then
              apiUserName=$(bin/magento encryption:encrypt --value "${apiUserName}")
              apiPassword=$(bin/magento encryption:encrypt --value "${apiPassword}")
              apiSignature=$(bin/magento encryption:encrypt --value "${apiSignature}")
            fi
          fi
          magento2ConfigPath=$(dirname "${magento2ConfigFile}")
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/payment/paypal_express/active" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/payment/paypal_express/debug" "1"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/payment/paypal_express/merchant_id" "${merchantAccountId}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/general/business_account" "${businessAccount}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/general/merchant_country" "DE"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/wpp/api_password" "${apiPassword}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/wpp/api_signature" "${apiSignature}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/wpp/api_username" "${apiUserName}"
          php "${currentPath}/add.php" "${magento2ConfigPath}" "system/default/paypal/wpp/sandbox_flag" "1"
          bin/magento app:config:import
        fi
      fi
    else
      echo "--- Configuring Paypal on remote server: ${server} ---"
    fi
  fi
done

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

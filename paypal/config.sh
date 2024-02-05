#!/bin/bash -e

currentPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scriptName="${0##*/}"

usage() {
  cat >&2 <<EOF

usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --environment     Name of environment (optional)
  --magentoVersion  Magento version
  --webPath         Web path
  --webUser         Web user
  --webGroup        Web group
  --addScript       Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.3.7 --webPath /var/www/magento/htdocs --addScript /tmp/script.php
EOF
}

trim() {
  echo -n "$1" | xargs
}

environment=
magentoVersion=
webPath=
webUser=
webGroup=
addScript=
businessAccount=
apiUserName=
apiPassword=
apiSignature=
merchantAccountId=

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

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  # Magento 1
  magento1ConfigFile="${webPath}/app/etc/local.xml"
  if [[ -e "${magento1ConfigFile}" ]]; then
    if [[ -L "${magento1ConfigFile}" ]]; then
      magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
    fi
    if [[ -f "${magento1ConfigFile}" ]]; then
      cd "${webPath}"
      encryptScript="shell/encrypt.php"
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
      cat <<EOF | tee "${configFile}" >/dev/null
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

elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  if [[ -n "${environment}" ]]; then
    magento2ConfigFile="${webPath}/app/etc/env/${environment}.php"
  else
    magento2ConfigFile="${webPath}/app/etc/config.php"
  fi

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

      php "${addScript}" "${magento2ConfigFile}" "system/default/payment/paypal_express/active" "1"
      php "${addScript}" "${magento2ConfigFile}" "system/default/payment/paypal_express/debug" "1"
      php "${addScript}" "${magento2ConfigFile}" "system/default/payment/paypal_express/merchant_id" "${merchantAccountId}"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/general/business_account" "${businessAccount}"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/general/merchant_country" "DE"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/wpp/api_password" "${apiPassword}"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/wpp/api_signature" "${apiSignature}"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/wpp/api_username" "${apiUserName}"
      php "${addScript}" "${magento2ConfigFile}" "system/default/paypal/wpp/sandbox_flag" "1"

      cd "${webPath}"
      bin/magento app:config:import
    else
      >&2 echo "Configuration file not found at: ${magento2ConfigFile}"
      exit 1
    fi
  else
    >&2 echo "Configuration file not found at: ${magento2ConfigFile}"
    exit 1
  fi
fi

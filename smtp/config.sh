#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --environment           Name of environment (optional)
  --magentoVersion        Magento version
  --smtpEnabled           Flag if SMTP is enabled
  --smtpHost              SMTP host name
  --smtpPort              SMTP host port
  --smtpProtocol          SMTP protocol
  --smtpAuthentication    SMTP authentication
  --smtpUser              SMTP user
  --smtpPassword          SMTP password
  --webPath               Web path
  --webUser               Web user (optional)
  --webGroup              Web group (optional)
  --mergeScript           Merge script (required if Magento 1)
  --mergeScriptPhpScript  Merge script PHP script (required if Magento 1)
  --addScript             Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion 2.4.5 --smtpEnabled yes --smtpHost smtp.mailserver.net --smtpPort 465 --smtpProtocol ssl --smtpAuthentication login --smtpUser user --smtpPassword password --webPath /var/www/magento/htdocs --addScript /tmp/add.php
EOF
}

environment=
magentoVersion=
smtpEnabled=
smtpHost=
smtpPort=
smtpProtocol=
smtpAuthentication=
smtpUser=
smtpPassword=

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

if [[ -z "${smtpEnabled}" ]]; then
  echo "No SMTP enabling specified!"
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
  echo "No configuration for SMTP integration in Magento 1 available"
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
      if [[ "${smtpEnabled}" == "yes" ]]; then
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/general/enabled" "1"
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/host" "${smtpHost}"
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/port" "${smtpPort}"
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/protocol" "${smtpProtocol}"
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/authentication" "${smtpAuthentication}"

        if [[ "${smtpAuthentication}" != "none" ]]; then
          php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/username" "${smtpUser}"
          php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/configuration_option/password" "${smtpPassword}"
        fi
      else
        php "${addScript}" "${magento2ConfigFile}" "system/default/smtp/general/enabled" "0"
      fi

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

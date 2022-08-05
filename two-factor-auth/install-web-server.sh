#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --magentoVersion  Magento version
  --webPath         Web path
  --enable          Enable two factor auth
  --disable         Disable two factor auth

Example: ${scriptName} --magentoVersion 2.4.1 --webPath /var/www/magento/htdocs --disable
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
webPath=
enable=0
disable=0

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

if [[ $(versionCompare "${magentoVersion}" "2.4.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.4.0") == 2 ]]; then
  cd "${webPath}"
  if [[ "${enable}" == 1 ]]; then
    echo "Enabling two factor auth"
    bin/magento module:enable Magento_TwoFactorAuth
  fi
  if [[ "${disable}" == 1 ]]; then
    echo "Disabling two factor auth"
    bin/magento module:disable Magento_TwoFactorAuth
  fi
else
  echo "Magento version does not have build in two factor auth"
fi

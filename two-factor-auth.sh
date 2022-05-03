#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -e  Enable two factor auth
  -d  Disable two factor auth

Example: ${scriptName} -d
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

enable=0
disable=0

while getopts hed? option; do
  case ${option} in
    h) usage; exit 1;;
    e) enable=1;;
    d) disable=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ $(versionCompare "${magentoVersion}" "2.4.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.4.0") == 2 ]]; then
  for server in "${serverList[@]}"; do
    webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
    if [[ -n "${webServer}" ]]; then
      type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      if [[ "${type}" == "local" ]]; then
        webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
        echo "--- Configuring two factor auth on local server: ${server} ---"
        cd "${webPath}"
        if [[ "${enable}" == 1 ]]; then
          echo "Enabling two factor auth"
          bin/magento module:enable Magento_TwoFactorAuth
        fi
        if [[ "${disable}" == 1 ]]; then
          echo "Disabling two factor auth"
          bin/magento module:disable Magento_TwoFactorAuth
        fi
      fi
    fi
  done
else
  echo "Magento version does not have build in two factor auth"
fi

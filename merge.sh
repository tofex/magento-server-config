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

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then

    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      currentUser="$(whoami)"
      if [[ -z "${webUser}" ]]; then
        webUser="${currentUser}"
      fi
      currentGroup="$(id -g -n)"
      if [[ -z "${webGroup}" ]]; then
        webGroup="${currentGroup}"
      fi
      echo "--- Merging on local server: ${server} ---"

      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          echo "Merging configuration in path: ${magento1ConfigPath}"
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "php ${currentPath}/merge.php \"${magento1ConfigPath}\""
          else
            php "${currentPath}/merge.php" "${magento1ConfigPath}"
          fi
        fi
      fi
    fi
  fi
done

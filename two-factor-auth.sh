#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

enable=0
disable=0

while getopts hed? option; do
  case "${option}" in
    h) usage; exit 1;;
    e) enable=1;;
    d) disable=1;;
    ?) usage; exit 1;;
  esac
done

if [[ "${enable}" == 1 ]]; then
  "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/two-factor-auth/install-web-server.sh" \
    --enable
elif [[ "${disable}" == 1 ]]; then
  "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/two-factor-auth/install-web-server.sh" \
    --disable
fi

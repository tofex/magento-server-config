#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Admin path

Example: ${scriptName} -p secret
EOF
}

trim()
{
  echo -n "$1" | xargs
}

adminPath=

while getopts hp:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) adminPath=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -z "${adminPath}" ]]; then
  adminPath=$(ini-parse "${currentPath}/../env.properties" "no" "install" "adminPath")
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

"${currentPath}/../core/script/magento/database.sh" "${currentPath}/admin/database.sh" \
  -a "${adminPath}"

"${currentPath}/../core/script/magento/web-server/config.sh" "${currentPath}/admin/web-server.sh" \
  -a "${adminPath}"

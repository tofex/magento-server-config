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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

mailAddress=$(ini-parse "${currentPath}/../env.properties" "no" "install" "mailAddress")
if [[ -z "${mailAddress}" ]]; then
  mailAddress="webmaster@localhost.local"
fi

"${currentPath}/../core/script/database/single.sh" "${currentPath}/mails/database.sh"
"${currentPath}/../core/script/magento/web-server/config.sh" "${currentPath}/mails/web-server.sh" \
  -a "${mailAddress}"

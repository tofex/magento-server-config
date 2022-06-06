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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

randomPrefix=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
echo "Adding random prefix: ${randomPrefix} to all entity increment ids"

"${currentPath}/../core/script/database/single.sh" "${currentPath}/mails/database.sh" \
  -r "${randomPrefix}"


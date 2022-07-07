#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -r  Flag to mark all notifications as read
  -o  Flag to mark all notifications as removed

Example: ${scriptName} -f
EOF
}

trim()
{
  echo -n "$1" | xargs
}

read=0
removed=0

while getopts hro? option; do
  case "${option}" in
    h) usage; exit 1;;
    r) read=1;;
    o) removed=1;;
    ?) usage; exit 1;;
  esac
done

"${currentPath}/../core/script/run.sh" "database" "${currentPath}/notification/database.sh" \
  --read "${read}" \
  --removed "${removed}"

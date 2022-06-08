#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -e  Enable admin usage
  -d  Disable admin usage

Example: ${scriptName} -e
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
  case "${option}" in
    h) usage; exit 1;;
    e) enable=1;;
    d) disable=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ "${enable}" == 1 ]]; then
  "${currentPath}/../core/script/magento/database.sh" "${currentPath}/admin-usage/database.sh" -a
fi

if [[ "${disable}" == 1 ]]; then
  "${currentPath}/../core/script/magento/database.sh" "${currentPath}/admin-usage/database.sh" -i
fi

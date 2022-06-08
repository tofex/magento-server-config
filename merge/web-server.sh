#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -u  Web user
  -g  Web group
  -m  Merge script

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=
mergeScript=

while getopts hn:w:u:g:t:v:p:z:x:y:m:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    m) mergeScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

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

if [[ -z "${mergeScript}" ]]; then
  echo "No merge script specified!"
  usage
  exit 1
fi

magento1ConfigFile="${webPath}/app/etc/local.xml"

if [[ -e "${magento1ConfigFile}" ]]; then
  if [[ -L "${magento1ConfigFile}" ]]; then
    magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
  fi

  if [[ -f "${magento1ConfigFile}" ]]; then
    magento1ConfigPath=$(dirname "${magento1ConfigFile}")
    echo "Merging configuration in path: ${magento1ConfigPath}"

    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "php ${mergeScript} \"${magento1ConfigPath}\""
    else
      php "${mergeScript}" "${magento1ConfigPath}"
    fi
  fi
fi

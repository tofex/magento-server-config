#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -f  Force to overwrite existing configuration
  -i  Ignore existing configuration

Example: ${scriptName} -f
EOF
}

trim()
{
  echo -n "$1" | xargs
}

force=0
ignore=0

while getopts hfi? option; do
  case "${option}" in
    h) usage; exit 1;;
    f) force=1;;
    i) ignore=1;;
    ?) usage; exit 1;;
  esac
done

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  usage
  exit 1
fi

"${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/init/web-server.sh" \
  --force "${force}" \
  --ignore "${ignore}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/../ops/create-shared/web-server.sh" \
    -f "app/etc/local.xml" \
    -o

  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/local.xml"
else
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/../ops/create-shared/web-server.sh" \
    -f "app/etc/env.php" \
    -o
  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/env.php"

  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/../ops/create-shared/web-server.sh" \
    -f "app/etc/config.php" \
    -o
  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/config.php"
fi

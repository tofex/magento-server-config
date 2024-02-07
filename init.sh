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
  -e  Setup environment configuration file (optional)

Example: ${scriptName} -f -e local
EOF
}

trim()
{
  echo -n "$1" | xargs
}

force=
ignore=
environmentSetup=

while getopts hfie:? option; do
  case "${option}" in
    h) usage; exit 1;;
    f) force=1;;
    i) ignore=1;;
    e) environmentSetup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${force}" ]]; then
  force=0
fi

if [[ -z "${ignore}" ]]; then
  ignore=0
fi

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

if [[ -n "${environmentSetup}" ]]; then
  "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/init/web-server.sh" \
    --force "${force}" \
    --ignore "${ignore}" \
    --environmentSetup "${environmentSetup}"
else
  "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/init/web-server.sh" \
    --force "${force}" \
    --ignore "${ignore}"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/../ops/create-shared/web-server-check.sh" \
    --fileName "app/etc/local.xml")

  if [[ "${fileStatus}" == "mounted" ]]; then
    echo "app/etc/local.xml is mounted"
  else
    "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/../ops/create-shared/web-server.sh" \
      --fileName "app/etc/local.xml" \
      --overwrite
    "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/../ops/create-shared/web-server-env.sh" \
      --fileName "app/etc/local.xml"
  fi
else
  fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/../ops/create-shared/web-server-check.sh" \
    --fileName "app/etc/env.php")

  if [[ "${fileStatus}" == "mounted" ]]; then
    echo "app/etc/env.php is mounted"
  else
    "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/../ops/create-shared/web-server.sh" \
      --fileName "app/etc/env.php" \
      --overwrite
    "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/../ops/create-shared/web-server-env.sh" \
      --fileName "app/etc/env.php"
  fi

  fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/../ops/create-shared/web-server-check.sh" \
    --fileName "app/etc/config.php")

  if [[ "${fileStatus}" == "mounted" ]]; then
    echo "app/etc/config.php is mounted"
  else
    "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/../ops/create-shared/web-server.sh" \
      --fileName "app/etc/config.php" \
      --overwrite
    "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/../ops/create-shared/web-server-env.sh" \
      --fileName "app/etc/config.php"
  fi

  if [[ -n "${environmentSetup}" ]]; then
    fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/../ops/create-shared/web-server-check.sh" \
      --fileName "app/etc/env/base.php")

    if [[ "${fileStatus}" == "mounted" ]]; then
      echo "app/etc/env/base.php is mounted"
    else
      "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/../ops/create-shared/web-server.sh" \
        --fileName "app/etc/env/base.php" \
        --overwrite
      "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/../ops/create-shared/web-server-env.sh" \
        --fileName "app/etc/env/base.php"
    fi

    fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/../ops/create-shared/web-server-check.sh" \
      --fileName "app/etc/env/${environmentSetup}.php")

    if [[ "${fileStatus}" == "mounted" ]]; then
      echo "app/etc/env/${environmentSetup}.php is mounted"
    else
      "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/../ops/create-shared/web-server.sh" \
        --fileName "app/etc/env/${environmentSetup}.php" \
        --overwrite
      "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/../ops/create-shared/web-server-env.sh" \
        --fileName "app/etc/env/${environmentSetup}.php"
    fi

    ini-set "${currentPath}/../env.properties" yes system environment "${environmentSetup}"
  fi
fi

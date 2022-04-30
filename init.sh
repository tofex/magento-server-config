#!/bin/bash -e

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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
cryptKey=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "cryptKey")

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  echo "No crypt key specified!"
  exit 1
fi

now=$(LC_ALL=en_US.utf8 date "+%a, %d %b %Y %H:%M:%S %z")

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
      echo "--- Initalizing configuration on local server: ${server} ---"
      if [[ ${magentoVersion:0:1} == 1 ]]; then
        magento1ConfigPath="${webPath}/app/etc"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "mkdir -p ${magento1ConfigPath}"
        else
          mkdir -p "${magento1ConfigPath}"
        fi

        magento1ConfigFile="${magento1ConfigPath}/local.xml"
        if [[ -f "${magento1ConfigFile}" ]] && [[ "${force}" == 0 ]]; then
          echo "Configuration already exists!"
          exit 1
        fi

        if [[ -L "${magento1ConfigFile}" ]]; then
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "rm ${magento1ConfigFile}"
          else
            rm "${magento1ConfigFile}"
          fi
        fi

        cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${magento1ConfigFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <install>
            <date><![CDATA[${now}]]></date>
        </install>
        <crypt>
            <key><![CDATA[${cryptKey}]]></key>
        </crypt>
        <disable_local_modules>false</disable_local_modules>
        <session_save><![CDATA[files]]></session_save>
    </global>
</config>
EOF
        "${currentPath}/../ops/create-shared.sh" -f app/etc/local.xml -o
      else
        magento2ConfigPath="${webPath}/app/etc"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "mkdir -p ${magento2ConfigPath}"
        else
          mkdir -p "${magento2ConfigPath}"
        fi

        magento2EnvironmentFile="${magento2ConfigPath}/env.php"
        if [[ -f "${magento2EnvironmentFile}" ]]; then
          echo "Environment already exists!"
          if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
            exit 1
          fi
        fi

        if [[ -L "${magento2EnvironmentFile}" ]] && [[ "${ignore}" == 0 ]]; then
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "rm ${magento2EnvironmentFile}"
          else
            rm "${magento2EnvironmentFile}"
          fi
        fi

        magento2ConfigFile="${magento2ConfigPath}/config.php"
        if [[ -f "${magento2ConfigFile}" ]]; then
          echo "Configuration already exists!"
          if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
            exit 1
          fi
        fi

        if [[ -L "${magento2ConfigFile}" ]] && [[ "${ignore}" == 0 ]]; then
          if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
            sudo -H -u "${webUser}" bash -c "rm ${magento2ConfigFile}"
          else
            rm "${magento2ConfigFile}"
          fi
        fi

        if [[ ! -f "${magento2EnvironmentFile}" ]] || [[ "${ignore}" == 0 ]]; then
          echo "Creating environment file at: ${magento2EnvironmentFile}"
          cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${magento2EnvironmentFile}" > /dev/null
<?php
return array (
    'install' => array (
        'date' => '${now}'
    ),
    'crypt' => array (
        'key' => '${cryptKey}'
    ),
    'x-frame-options' => 'SAMEORIGIN',
    'session' => array (
        'save' => 'files'
    ),
    'cache_types' => array (
        'block_html' => 1,
        'collections' => 1,
        'compiled_config' => 1,
        'config' => 1,
        'config_integration' => 1,
        'config_integration_api' => 1,
        'config_webservice' => 1,
        'customer_notification' => 1,
        'db_ddl' => 1,
        'eav' => 1,
        'ec_cache' => 1,
        'full_page' => 1,
        'google_product' => 1,
        'layout' => 1,
        'reflection' => 1,
        'translate' => 1,
        'vertex' => 1
    )
);
EOF
        fi

        if [[ ! -f "${magento2ConfigFile}" ]] || [[ "${ignore}" == 0 ]]; then
          echo "Creating configuration file at: ${magento2ConfigFile}"
          cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${magento2ConfigFile}" > /dev/null
<?php
return [
    'modules' => []
];
EOF
        fi

        "${currentPath}/../ops/create-shared.sh" -f app/etc/env.php -o
        "${currentPath}/../ops/create-shared.sh" -f app/etc/config.php -o
      fi
    fi
  fi
done

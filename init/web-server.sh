#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --magentoVersion    Magento version
  --cryptKey          Crypt key of installation
  --webPath           Web path
  --webUser           Web user (optional)
  --webGroup          Web group (optional)
  --force             Force overwrite
  --ignore            Ignore existing files
  --environmentSetup  Setup environment configuration file (optional)

Example: ${scriptName}
EOF
}

magentoVersion=
cryptKey=
webPath=
webUser=
webGroup=
force=0
ignore=0
environmentSetup=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  echo "No crypt key specified!"
  usage
  exit 1
fi

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

now=$(LC_ALL=en_US.utf8 date "+%a, %d %b %Y %H:%M:%S %z")

if [[ ${magentoVersion:0:1} == 1 ]]; then
  magento1ConfigPath="${webPath}/app/etc"

  if [[ ! -d "${magento1ConfigPath}" ]]; then
    echo "Creating config path at: ${magento1ConfigPath}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "mkdir -p ${magento1ConfigPath}"
    else
      mkdir -p "${magento1ConfigPath}"
    fi
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
else
  magento2ConfigPath="${webPath}/app/etc"

  if [[ ! -d "${magento2ConfigPath}" ]]; then
    echo "Creating config path at: ${magento2ConfigPath}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "mkdir -p ${magento2ConfigPath}"
    else
      mkdir -p "${magento2ConfigPath}"
    fi
  fi

  if [[ -n "${environmentSetup}" ]]; then
    magento2ConfigEnvPath="${webPath}/app/etc/env"

    if [[ ! -d "${magento2ConfigEnvPath}" ]]; then
      echo "Creating config environment path at: ${magento2ConfigEnvPath}"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mkdir -p ${magento2ConfigEnvPath}"
      else
        mkdir -p "${magento2ConfigEnvPath}"
      fi
    fi
  fi

  magento2EnvironmentFile="${magento2ConfigPath}/env.php"
  if [[ -f "${magento2EnvironmentFile}" ]]; then
    if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
      >&2 echo "Environment file already exists!"
      exit 1
    else
      echo "Environment file already exists!"
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
    if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
      >&2 echo "Configuration file already exists!"
      exit 1
    else
      echo "Configuration file already exists!"
    fi
  fi

  if [[ -L "${magento2ConfigFile}" ]] && [[ "${ignore}" == 0 ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm ${magento2ConfigFile}"
    else
      rm "${magento2ConfigFile}"
    fi
  fi

  if [[ -n "${environmentSetup}" ]]; then
    magento2ConfigEnvBaseFile="${magento2ConfigEnvPath}/base.php"
    if [[ -f "${magento2ConfigEnvBaseFile}" ]]; then
      if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
        >&2 echo "Configuration environment base file already exists!"
        exit 1
      else
        echo "Configuration environment base file already exists!"
      fi
    fi

    if [[ -L "${magento2ConfigEnvBaseFile}" ]] && [[ "${ignore}" == 0 ]]; then
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm ${magento2ConfigEnvBaseFile}"
      else
        rm "${magento2ConfigEnvBaseFile}"
      fi
    fi

    magento2ConfigEnvFile="${magento2ConfigEnvPath}/${environmentSetup}.php"
    if [[ -f "${magento2ConfigEnvFile}" ]]; then
      if [[ "${force}" == 0 ]] && [[ "${ignore}" == 0 ]]; then
        >&2 echo "Configuration environment file already exists!"
        exit 1
      else
        echo "Configuration environment file already exists!"
      fi
    fi

    if [[ -L "${magento2ConfigEnvFile}" ]] && [[ "${ignore}" == 0 ]]; then
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm ${magento2ConfigEnvFile}"
      else
        rm "${magento2ConfigEnvFile}"
      fi
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

  if [[ -n "${environmentSetup}" ]]; then
    if [[ ! -f "${magento2ConfigEnvBaseFile}" ]] || [[ "${ignore}" == 0 ]]; then
      echo "Creating configuration file at: ${magento2ConfigEnvBaseFile}"
      cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${magento2ConfigEnvBaseFile}" > /dev/null
<?php
return [
];
EOF
    fi

    if [[ ! -f "${magento2ConfigEnvFile}" ]] || [[ "${ignore}" == 0 ]]; then
      echo "Creating configuration file at: ${magento2ConfigEnvFile}"
      cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${magento2ConfigEnvFile}" > /dev/null
<?php
return [
];
EOF
    fi
  fi
fi

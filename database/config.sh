#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                   Show this message
  --magentoVersion         Magento version
  --databaseHost           Database host
  --databasePort           Database port
  --databaseUser           Name of the database user
  --databasePassword       Password of the database user
  --databaseName           Name of the database
  --webPath                Web path
  --webUser                Web user (optional)
  --webGroup               Web group (optional)
  --mergeScript            Merge script (required if Magento 1)
  --mergeScriptPhpScript   Merge script PHP script (required if Magento 1)
  --addScript              Add PHP script (required if Magento 2)

Example: ${scriptName} --magentoVersion --webPath /var/www/magento/htdocs --addScript /tmp/add.php
EOF
}

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
webPath=
webUser=
webGroup=
mergeScript=
mergeScriptPhpScript=
addScript=

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

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  usage
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  usage
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  usage
  exit 1
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  if [[ -z "${mergeScript}" ]]; then
    echo "No merge script specified!"
    usage
    exit 1
  fi

  if [[ -z "${mergeScriptPhpScript}" ]]; then
    echo "No merge script PHP script specified!"
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
      configFile="${magento1ConfigPath}/local.database.xml"
      echo "Creating configuration file: ${configFile}"
      cat <<EOF | sudo -H -u "${webUser}" bash -c "tee ${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <global>
        <resources>
            <default_setup>
                <connection>
                    <host><![CDATA[${databaseHost}]]></host>
                    <username><![CDATA[${databaseUser}]]></username>
                    <password><![CDATA[${databasePassword}]]></password>
                    <dbname><![CDATA[${databaseName}]]></dbname>
                    <model><![CDATA[mysql4]]></model>
                    <type><![CDATA[pdo_mysql]]></type>
                    <pdoType><![CDATA[]]></pdoType>
                    <initStatements><![CDATA[SET NAMES utf8;]]></initStatements>
                    <active>1</active>
                </connection>
            </default_setup>
        </resources>
    </global>
</config>
EOF

      "${mergeScript}" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -m "${mergeScriptPhpScript}"
    fi
  fi
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  magento2ConfigFile="${webPath}/app/etc/config.php"

  if [[ -e "${magento2ConfigFile}" ]]; then
    if [[ -L "${magento2ConfigFile}" ]]; then
      magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
    fi

    if [[ -f "${magento2ConfigFile}" ]]; then
      magento2ConfigPath=$(dirname "${magento2ConfigFile}")

      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/table_prefix\" \"\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/host\" \"${databaseHost}\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/username\" \"${databaseUser}\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/password\" \"${databasePassword}\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/dbname\" \"${databaseName}\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/model\" \"mysql4\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/engine\" \"innodb\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/initStatements\" \"SET NAMES utf8;\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"db/connection/default/active\" \"1\""
        sudo -H -u "${webUser}" bash -c "php ${currentPath}/add.php \"${magento2ConfigPath}\" \"resource/default_setup/connection\" \"default\""
      else
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/table_prefix" ""
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/host" "${databaseHost}"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/username" "${databaseUser}"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/password" "${databasePassword}"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/dbname" "${databaseName}"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/model" "mysql4"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/engine" "innodb"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/initStatements" "SET NAMES utf8;"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "db/connection/default/active" "1"
        php "${currentPath}/add.php" "${magento2ConfigPath}" "resource/default_setup/connection" "default"
      fi
    fi
  fi
fi

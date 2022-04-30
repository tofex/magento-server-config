#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Admin path

Example: ${scriptName} -p secret
EOF
}

trim()
{
  echo -n "$1" | xargs
}

adminPath=

while getopts hp:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) adminPath=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

adminPath=$(ini-parse "${currentPath}/../env.properties" "no" "install" "adminPath")
if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

database=
databaseHost=
databaseServerName=
for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      databaseHost="localhost"
      databaseServerName="${server}"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      databaseServerName="${server}"
    fi
    break
  fi
done

if [[ -z "${databaseHost}" ]]; then
  echo "No database settings found"
  exit 1
fi

databasePort=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

rm -rf /tmp/config-admin.sh

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Configuring admin path on local server: ${server} ---"

      # Magento 1
      magento1ConfigFile="${webPath}/app/etc/local.xml"
      if [[ -e "${magento1ConfigFile}" ]]; then
        if [[ -L "${magento1ConfigFile}" ]]; then
          magento1ConfigFile=$(readlink -f "${magento1ConfigFile}")
        fi
        if [[ -f "${magento1ConfigFile}" ]]; then
          magento1ConfigPath=$(dirname "${magento1ConfigFile}")
          configFile="${magento1ConfigPath}/local.admin.xml"
          echo "Creating configuration file: ${configFile}"
          cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <admin>
        <routers>
            <adminhtml>
                <args>
                    <frontName><![CDATA[${adminPath}]]></frontName>
                </args>
            </adminhtml>
        </routers>
    </admin>
</config>
EOF
          "${currentPath}/merge.sh"
        fi
        cat <<EOF | tee "/tmp/config-admin.sh" > /dev/null
#!/bin/bash -e
export MYSQL_PWD="${databasePassword}"
echo "Deleting previous entries in database"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom_path';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom_path';"
EOF
        if [[ "${adminPath}" != "admin" ]]; then
          cat <<EOF | tee -a "/tmp/config-admin.sh" > /dev/null
echo "Adding custom path settings"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/use_custom', '1');"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/use_custom_path', '${adminPath}');"
EOF
        fi
      fi

      # Magento 2
      magento2ConfigFile="${webPath}/app/etc/env.php"
      if [[ -e "${magento2ConfigFile}" ]]; then
        if [[ -L "${magento2ConfigFile}" ]]; then
          magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
        fi
        if [[ -f "${magento2ConfigFile}" ]]; then
          magento2ConfigPath=$(dirname "${magento2ConfigFile}")
          php "${currentPath}/add.php" "${magento2ConfigPath}" "backend/frontName" "${adminPath}"
        fi
        cat <<EOF | tee "/tmp/config-admin.sh" > /dev/null
#!/bin/bash -e
export MYSQL_PWD="${databasePassword}"
echo "Deleting previous entries in database"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/custom_path';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom';"
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "DELETE FROM core_config_data WHERE path = 'admin/url/use_custom_path';"
EOF
        #if [[ "${adminPath}" != "admin" ]]; then
        #  cat <<EOF | tee -a "/tmp/config-admin.sh" > /dev/null
#echo "Adding custom path settings"
#mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/use_custom', '1');"
#mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/url/custom_path', '${adminPath}');"
#EOF
        #fi
      fi
    fi
  fi
done

if [[ -f /tmp/config-admin.sh ]]; then
  chmod +x /tmp/config-admin.sh

  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "type")

  echo "--- Updating admin path on database server: ${server} ---"
  if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "docker" ]]; then
    /tmp/config-admin.sh
  elif [[ "${serverType}" == "ssh" ]]; then
    user=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "user")
    echo "Copying script to ${user}@${databaseHost}:/tmp/config-admin.sh"
    scp -q "/tmp/config-admin.sh" "${user}@${databaseHost}:/tmp/config-admin.sh"
    ssh "${user}@${databaseHost}" "/tmp/config-admin.sh"
    ssh "${user}@${databaseHost}" "rm -rf /tmp/config-admin.sh"
  else
    echo "Invalid database server type: ${serverType}"
    exit 1
  fi
fi

rm -rf /tmp/config-admin.sh

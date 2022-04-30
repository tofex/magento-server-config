#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -u  User name, default: dev-admin
  -p  User password, default: dev-admin12345
  -f  Hash function, default: md5
  -l  Hash length (required for sha2)

Example: ${scriptName} -u username -p password
EOF
}

trim()
{
  echo -n "$1" | xargs
}

userName="dev-admin"
userPassword="dev-admin12345"
hash="md5"
hashLength=

while getopts hu:p:f:l:? option; do
  case "${option}" in
    h) usage; exit 1;;
    u) userName=$(trim "$OPTARG");;
    p) userPassword=$(trim "$OPTARG");;
    f) hash=$(trim "$OPTARG");;
    l) hashLength=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${userName}" ]]; then
  echo "No user name specified!"
  exit 1
fi

if [[ -z "${userPassword}" ]]; then
  echo "No user password specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

if [[ ${magentoVersion:0:1} == 1 ]]; then
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

  cat <<EOF | tee "/tmp/config-backend-user.sh" > /dev/null
#!/bin/bash -e
export MYSQL_PWD="${databasePassword}"
adminColumns=( \$(mysql -B -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" --disable-column-names -e "select column_name from information_schema.columns where table_schema = \"${databaseName}\" and table_name=\"admin_user\" and column_name in (\"country_id\", \"customer_anonymous_id\", \"tax\");") )
if [[ "\${#adminColumns[@]}" -eq 3 ]]; then
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password, country_id, customer_anonymous_id, tax) VALUES ('AD', 'MIN', '${userName}@tofex.de', '${userName}', CONCAT(${hash}('dB${userPassword}'), ':dB'), '', 0, 0);"
else
EOF
  if [[ -n "${hashLength}" ]]; then
    cat <<EOF | tee -a "/tmp/config-backend-user.sh" > /dev/null
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password) VALUES ('AD', 'MIN', '${userName}@tofex.de', '${userName}', CONCAT(${hash}('dB${userPassword}', ${hashLength}), ':dB'));"
EOF
  else
    cat <<EOF | tee -a "/tmp/config-backend-user.sh" > /dev/null
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password) VALUES ('AD', 'MIN', '${userName}@tofex.de', '${userName}', CONCAT(${hash}('dB${userPassword}'), ':dB'));"
EOF
  fi
  cat <<EOF | tee -a "/tmp/config-backend-user.sh" > /dev/null
fi
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_role (parent_id, tree_level, role_type, user_id, role_name) VALUES (1, 2, 'U', (SELECT user_id FROM admin_user WHERE username = '${userName}'), 'Admins' );"
EOF

  chmod +x /tmp/config-backend-user.sh

  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "type")

  echo "--- Creating backend user on server: ${server} ---"
  if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "docker" ]]; then
    /tmp/config-backend-user.sh
  elif [[ "${serverType}" == "ssh" ]]; then
    user=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "user")
    echo "Copying script to ${user}@${databaseHost}:/tmp/config-backend-user.sh"
    scp -q "/tmp/config-backend-user.sh" "${user}@${databaseHost}:/tmp/config-backend-user.sh"
    ssh "${user}@${databaseHost}" "/tmp/config-backend-user.sh"
    ssh "${user}@${databaseHost}" "rm -rf /tmp/config-backend-user.sh"
  else
    echo "Invalid database server type: ${serverType}"
    exit 1
  fi

  rm -rf /tmp/config-backend-user.sh
else
  for server in "${serverList[@]}"; do
    webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
    if [[ -n "${webServer}" ]]; then
      serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      if [[ "${serverType}" == "local" ]]; then
        webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
        echo "--- Configuring backend user on server: ${server} ---"
        cd "${webPath}"
        bin/magento admin:user:create --admin-user="${userName}" --admin-password="${userPassword}" --admin-firstname="Admin" --admin-lastname="Min" --admin-email="${userName}@tofex.de"
      fi
    fi
  done
fi

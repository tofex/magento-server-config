#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

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

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

randomPrefix=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
echo "Adding random prefix: ${randomPrefix} to all entity increment ids"

cat <<EOF | tee "/tmp/config-prefix.sh" > /dev/null
#!/bin/bash -e
echo "Update prefixes in database"
export MYSQL_PWD="${databasePassword}"
EOF

if [[ ${magentoVersion:0:1} == 1 ]]; then
  cat <<EOF | tee -a "/tmp/config-prefix.sh" > /dev/null
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE eav_entity_store SET INCREMENT_PREFIX = CONCAT(store_id, '${randomPrefix}');"
EOF
else
  cat <<EOF | tee -a "/tmp/config-prefix.sh" > /dev/null
mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE eav_entity_store SET INCREMENT_PREFIX = CONCAT(store_id, '${randomPrefix}');"
EOF
fi

chmod +x /tmp/config-prefix.sh

serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "type")

echo "--- Updating prefixes on database server: ${server} ---"
if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "docker" ]]; then
  /tmp/config-prefix.sh
elif [[ "${serverType}" == "ssh" ]]; then
  user=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "user")
  echo "Copying script to ${user}@${databaseHost}:/tmp/config-prefix.sh"
  scp -q "/tmp/config-prefix.sh" "${user}@${databaseHost}:/tmp/config-prefix.sh"
  ssh "${user}@${databaseHost}" "/tmp/config-prefix.sh"
  ssh "${user}@${databaseHost}" "rm -rf /tmp/config-prefix.sh"
else
  echo "Invalid database server type: ${serverType}"
  exit 1
fi
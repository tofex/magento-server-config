#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -n  User name, default: dev-admin
  -w  User password, default: dev-admin12345
  -e  E-Mail address
  -f  Hash function, default: md5
  -l  Hash length (required for sha2)
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database

Example: ${scriptName} -v 2.3.7 -n username -w password -e no@one.com -u magento -p magento -b magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
userName="dev-admin"
userPassword="dev-admin12345"
userMail=""
hash="md5"
hashLength=

while getopts hv:n:w:e:f:l:o:p:u:s:b:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    n) userName=$(trim "$OPTARG");;
    w) userPassword=$(trim "$OPTARG");;
    e) userMail=$(trim "$OPTARG");;
    f) hash=$(trim "$OPTARG");;
    l) hashLength=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${userName}" ]]; then
  echo "No user name specified!"
  exit 1
fi

if [[ -z "${userPassword}" ]]; then
  echo "No user password specified!"
  exit 1
fi

if [[ -z "${userMail}" ]]; then
  userMail="${userName}@localhost.local"
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
  export MYSQL_PWD="${databasePassword}"
  adminColumns=( $(mysql -B -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" --disable-column-names -e "select column_name from information_schema.columns where table_schema = \"${databaseName}\" and table_name=\"admin_user\" and column_name in (\"country_id\", \"customer_anonymous_id\", \"tax\");") )
  if [[ "${#adminColumns[@]}" -eq 3 ]]; then
    mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password, country_id, customer_anonymous_id, tax) VALUES ('Ad', 'Min', '${userMail}', '${userName}', CONCAT(${hash}('dB${userPassword}'), ':dB'), '', 0, 0);"
  else
    if [[ -n "${hashLength}" ]] && [[ "${hashLength}" -gt 0 ]]; then
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password) VALUES ('Ad', 'Min', '${userMail}', '${userName}', CONCAT(${hash}('dB${userPassword}', ${hashLength}), ':dB'));"
    else
      mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_user (firstname, lastname, email, username, password) VALUES ('Ad', 'Min', '${userMail}', '${userName}', CONCAT(${hash}('dB${userPassword}'), ':dB'));"
    fi
  fi
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "REPLACE INTO admin_role (parent_id, tree_level, role_type, user_id, role_name) VALUES (1, 2, 'U', (SELECT user_id FROM admin_user WHERE username = '${userName}'), 'Admins' );"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  echo "No database changes required for Magento ${magentoVersion}"
fi

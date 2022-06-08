#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database
  -n  User name, default: dev-admin
  -w  User password, default: dev-admin12345
  -a  E-Mail address
  -f  Hash function, default: md5
  -l  Hash length (required for sha2)

Example: ${scriptName} -m 2.3.7 -u magento -p magento -b magento -n username -w password -a no@one.com
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
userName=
userPassword=
userMail=
hash=
hashLength=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:n:w:a:f:l:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    n) userName=$(trim "$OPTARG");;
    w) userPassword=$(trim "$OPTARG");;
    a) userMail=$(trim "$OPTARG");;
    f) hash=$(trim "$OPTARG");;
    l) hashLength=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
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

if [[ -z "${userName}" ]]; then
  userName="dev-admin"
fi

if [[ -z "${userPassword}" ]]; then
  userPassword="dev-admin12345"
fi

if [[ -z "${userMail}" ]]; then
  userMail="${userName}@localhost.local"
fi

if [[ -z "${hash}" ]]; then
  hash="md5"
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
  echo "No database action required for Magento ${magentoVersion}"
fi

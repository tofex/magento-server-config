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
  -e  E-Mail address
  -f  Hash function, default: md5
  -l  Hash length (required for sha2)

Example: ${scriptName} -u username -p password -e no@one.com
EOF
}

trim()
{
  echo -n "$1" | xargs
}

userName="dev-admin"
userPassword="dev-admin12345"
userMail=""
hash=
hashLength=

while getopts hu:p:e:f:l:? option; do
  case "${option}" in
    h) usage; exit 1;;
    u) userName=$(trim "$OPTARG");;
    p) userPassword=$(trim "$OPTARG");;
    e) userMail=$(trim "$OPTARG");;
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

if [[ -z "${userMail}" ]]; then
  userMail="${userName}@localhost.local"
fi

if [[ -z "${hash}" ]]; then
  hash="md5"
fi

if [[ -z "${hashLength}" ]]; then
  hashLength=0
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

"${currentPath}/../core/script/database-single.sh" "${currentPath}/backend-user-local-db.sh" \
  -v "${magentoVersion}" \
  -n "${userName}" \
  -w "${userPassword}" \
  -e "${userMail}" \
  -f "${hash}" \
  -l "${hashLength}"

"${currentPath}/../core/script/web-server-single.sh" "${currentPath}/backend-user-local-web.sh" \
  -v "${magentoVersion}" \
  -u "${userName}" \
  -p "${userPassword}" \
  -e "${userMail}"

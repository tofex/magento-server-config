#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -w  Web path
  -u  User name, default: dev-admin
  -p  User password, default: dev-admin12345
  -e  E-Mail address, default: <userName>@localhost.local

Example: ${scriptName} -v 2.3.7 -w /var/www/magento/htdocs -u username -p password -e no@one.com
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
webPath=
userName=
userPassword=
eMailAddress=

while getopts hv:w:u:p:e:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) userName=$(trim "$OPTARG");;
    p) userPassword=$(trim "$OPTARG");;
    e) eMailAddress=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ -z "${userName}" ]]; then
  userName="dev-admin"
fi

if [[ -z "${userPassword}" ]]; then
  userPassword="dev-admin12345"
fi

if [[ -z "${eMailAddress}" ]]; then
  eMailAddress="${userName}@localhost.local"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No web changes required for Magento ${magentoVersion}"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  cd "${webPath}"
  bin/magento admin:user:create --admin-user="${userName}" --admin-password="${userPassword}" --admin-firstname="Ad" --admin-lastname="Min" --admin-email="${eMailAddress}"
fi

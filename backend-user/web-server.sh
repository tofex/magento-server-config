#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Web path
  -a  User name, default: dev-admin
  -s  User password, default: dev-admin12345
  -i  E-Mail address, default: <userName>@localhost.local

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs -a username -s password -i no@one.com
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
userMail=

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:a:s:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    a) userName=$(trim "$OPTARG");;
    s) userPassword=$(trim "$OPTARG");;
    i) userMail=$(trim "$OPTARG");;
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

if [[ -z "${userMail}" ]]; then
  userMail="${userName}@dummy.host"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No web action required for Magento ${magentoVersion}"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  echo cd "${webPath}"
  cd "${webPath}"
  echo bin/magento admin:user:create --admin-user="${userName}" --admin-password="${userPassword}" --admin-firstname="Ad" --admin-lastname="Min" --admin-email="${userMail}"
  bin/magento admin:user:create --admin-user="${userName}" --admin-password="${userPassword}" --admin-firstname="Ad" --admin-lastname="Min" --admin-email="${userMail}"
fi

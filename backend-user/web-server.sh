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
  -n  User name, default: dev-admin
  -s  User password, default: dev-admin12345
  -a  E-Mail address, default: <userName>@localhost.local

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs -n username -s password -a no@one.com
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

while getopts hm:e:d:r:w:u:g:t:v:p:z:x:y:n:s:a:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    n) userName=$(trim "$OPTARG");;
    s) userPassword=$(trim "$OPTARG");;
    a) userMail=$(trim "$OPTARG");;
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
  userMail="${userName}@localhost.local"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  echo "No web action required for Magento ${magentoVersion}"
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  cd "${webPath}"
  bin/magento admin:user:create --admin-user="${userName}" --admin-password="${userPassword}" --admin-firstname="Ad" --admin-lastname="Min" --admin-email="${userMail}"
fi

#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -b  Business account
  -u  API user name
  -p  API password
  -s  API signature
  -m  Merchant account id

Example: ${scriptName} -f
EOF
}

trim()
{
  echo -n "$1" | xargs
}

businessAccount=
apiUserName=
apiPassword=
apiSignature=
merchantAccountId=

while getopts hb:u:p:s:m:? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) businessAccount=$(trim "$OPTARG");;
    u) apiUserName=$(trim "$OPTARG");;
    p) apiPassword=$(trim "$OPTARG");;
    s) apiSignature=$(trim "$OPTARG");;
    m) merchantAccountId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${businessAccount}" ]] && [[ -z "${apiUserName}" ]] && [[ -z "${apiPassword}" ]] && [[ -z "${apiSignature}" ]] && [[ -z "${merchantAccountId}" ]]; then
  businessAccount="development@tofex.de"
  apiUserName="development_api1.tofex.de"
  apiPassword="CDE6PD9LJ2Y2FY43"
  apiSignature="AFcWxV21C7fd0v3bYYYRCpSSRl31A3gMBpif1IPuWzAnR5VZiWNiT-iB"
  merchantAccountId="XHX9XT49M35DQ"
fi

if [[ -z "${businessAccount}" ]]; then
  echo "No business account defined!"
  exit 1
fi

if [[ -z "${apiUserName}" ]]; then
  echo "No API user name defined!"
  exit 1
fi

if [[ -z "${apiPassword}" ]]; then
  echo "No API user password defined!"
  exit 1
fi

if [[ -z "${apiSignature}" ]]; then
  echo "No API signature defined!"
  exit 1
fi

if [[ -z "${merchantAccountId}" ]]; then
  echo "No merchant account id defined!"
  exit 1
fi

"${currentPath}/../core/script/run.sh" "database" "${currentPath}/paypal/database.sh"
"${currentPath}/../core/script/run.sh" "config,config,install,webServer" "${currentPath}/paypal/config.sh" \
  --businessAccount "${businessAccount}" \
  --apiUserName "${apiUserName}" \
  --apiPassword "${apiPassword}" \
  --apiSignature "${apiSignature}" \
  --merchantAccountId "${merchantAccountId}"

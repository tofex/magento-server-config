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
  -u  Web user
  -g  Web group
  -a  Admin path, default: admin
  -s  Merge script (required if Magento 1)
  -c  Merge script PHP script (required if Magento 1)
  -d  Add PHP script (required if Magento 2)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs -a customadmin -i /tmp/script.php
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
webPath=
webUser=
webGroup=
adminPath=
mergeScript=
mergeScriptPhpScript=
addScript=

while getopts hm:e:d:r:w:u:g:t:v:p:z:x:y:a:s:c:d:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    a) adminPath=$(trim "$OPTARG");;
    s) mergeScript=$(trim "$OPTARG");;
    c) mergeScriptPhpScript=$(trim "$OPTARG");;
    i) addScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  # Magento 1
  if [[ -z "${mergeScript}" ]]; then
    echo "No merge script specified!"
    usage
    exit 1
  fi

  if [[ -z "${mergeScriptPhpScript}" ]]; then
    echo "No merge script PHP script specified!"
    usage
    exit 1
  fi

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

      "${mergeScript}" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -m "${mergeScriptPhpScript}"
    fi
  fi
elif [[ ${magentoVersion:0:1} == 2 ]]; then
  # Magento 2
  if [[ -z "${addScript}" ]]; then
    echo "No add script specified!"
    usage
    exit 1
  fi

  magento2ConfigFile="${webPath}/app/etc/env.php"

  if [[ -L "${magento2ConfigFile}" ]]; then
    magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
  fi

  if [[ -f "${magento2ConfigFile}" ]]; then
    magento2ConfigPath=$(dirname "${magento2ConfigFile}")
    php "${addScript}" "${magento2ConfigPath}" "backend/frontName" "${adminPath}"
  fi
fi

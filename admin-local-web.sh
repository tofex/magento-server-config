#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -a  Admin path, default: admin
  -u  Web user
  -g  Web group
  -v  Magento version
  -m  Merge script (required if Magento 1)
  -c  Merge script PHP script (required if Magento 1)
  -d  Add PHP script (required if Magento 2)

Example: ${scriptName} -w /var/www/magento/htdocs -a customadmin -v 2.3.7 -d /tmp/add.php
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
adminPath=
webUser=
webGroup=
magentoVersion=
mergeScript=
mergeScriptPhpScript=
addScript=

while getopts hw:a:u:g:v:m:c:d:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    a) adminPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    v) magentoVersion=$(trim "$OPTARG");;
    m) mergeScript=$(trim "$OPTARG");;
    c) mergeScriptPhpScript=$(trim "$OPTARG");;
    d) addScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
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
  fi

  "${mergeScript}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -m "${mergeScriptPhpScript}"
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

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
  -a  Mail address, default: webmaster@localhost.local

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs -a webmaster@localhost.local
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
mailAddress=
mergeScript=
mergeScriptPhpScript=
addScript=

while getopts hm:e:d:r:w:u:g:t:v:p:z:x:y:a:s:c:i:? option; do
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
    a) mailAddress=$(trim "$OPTARG");;
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
      configFile="${magento1ConfigPath}/local.mails.xml"
      echo "Creating configuration file: ${configFile}"
      cat <<EOF | tee "${configFile}" > /dev/null
<?xml version="1.0"?>
<config>
    <default>
        <contacts>
            <email>
                <recipient_email><![CDATA[${mailAddress}]]></recipient_email>
            </email>
        </contacts>
        <sales_email>
            <order>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </order>
            <invoice>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </invoice>
            <shipment>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </shipment>
            <creditmemo>
                <copy_to><![CDATA[${mailAddress}]]></copy_to>
            </creditmemo>
            <notification>
                <emails><![CDATA[${mailAddress}]]></emails>
            </notification>
        </sales_email>
        <system>
            <cron>
                <error_email><![CDATA[${mailAddress}]]></error_email>
            </cron>
            <log>
                <error_email><![CDATA[${mailAddress}]]></error_email>
            </log>
        </system>
        <trans_email>
            <ident_general>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_general>
            <ident_sales>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_sales>
            <ident_support>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_support>
            <ident_custom1>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_custom1>
            <ident_custom2>
                <email><![CDATA[${mailAddress}]]></email>
            </ident_custom2>
        </trans_email>
    </default>
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

  if [[ -e "${magento2ConfigFile}" ]]; then
    if [[ -L "${magento2ConfigFile}" ]]; then
      magento2ConfigFile=$(readlink -f "${magento2ConfigFile}")
    fi

    if [[ -f "${magento2ConfigFile}" ]]; then
      magento2ConfigPath=$(dirname "${magento2ConfigFile}")
      php "${addScript}" "${magento2ConfigPath}" "contact/email/recipient_email" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/creditmemo_comment/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/creditmemo/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/invoice_comment/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/invoice/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/order_comment/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/order/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/shipment_comment/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "sales_email/shipment/copy_to" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "trans_email/ident_custom1/email" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "trans_email/ident_custom2/email" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "trans_email/ident_general/email" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "trans_email/ident_sales/email" "${mailAddress}"
      php "${addScript}" "${magento2ConfigPath}" "trans_email/ident_support/email" "${mailAddress}"
    fi
  fi
fi

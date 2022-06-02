#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Admin path

Example: ${scriptName} -p secret
EOF
}

trim()
{
  echo -n "$1" | xargs
}

copyFileToSSH()
{
  sshUser="${1}"
  sshHost="${2}"
  filePath="${3}"

  fileName=$(basename "${filePath}")
  remoteFileName="/tmp/${fileName}"

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

executeScriptWithSSH()
{
  sshUser="${1}"
  shift
  sshHost="${1}"
  shift
  filePath="${1}"
  shift
  parameters=("$@")

  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}"

  fileName=$(basename "${filePath}")
  remoteFileName="/tmp/${fileName}"

  echo "Executing script at: ${sshUser}@${sshHost}:${remoteFileName}"
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
}

removeFileFromSSH()
{
  sshUser="${1}"
  sshHost="${2}"
  filePath="${3}"

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

adminPath=

while getopts hp:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) adminPath=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -z "${adminPath}" ]]; then
  adminPath=$(ini-parse "${currentPath}/../env.properties" "no" "install" "adminPath")
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

"${currentPath}/../core/script/database-single.sh" "${currentPath}/admin-local-db.sh" \
  -a "${adminPath}" \
  -v "${magentoVersion}"

"${currentPath}/../core/script/web-server-single.sh" "${currentPath}/admin-local-web.sh" \
  -a "${adminPath}" \
  -v "${magentoVersion}" \
  -m "${currentPath}/merge-local.sh" \
  -c "${currentPath}/merge.php" \
  -d "${currentPath}/add.php"

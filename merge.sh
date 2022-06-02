#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
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

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
    webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${type}" == "local" ]]; then
      echo "--- Merging on local server: ${server} ---"
      "${currentPath}/merge-local.sh" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -m "${currentPath}/merge.php"
    elif [[ "${type}" == "ssh" ]]; then
      echo "--- Merging on remote server: ${server} ---"
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      copyFileToSSH "${sshUser}" "${sshHost}" "${currentPath}/merge.php"

      executeScriptWithSSH "${sshUser}" "${sshHost}" "${currentPath}/merge-local.sh" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -m "/tmp/merge.php"

      removeFileFromSSH "${sshUser}" "${sshHost}" /tmp/merge.php
    fi
  fi
done

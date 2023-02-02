#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

adminHostName=$("${currentPath}/../core/server/host/admin.sh" | cat)

if [[ -z "${adminHostName}" ]]; then
  adminHostName=$("${currentPath}/../core/server/host/single.sh" | cat)
fi

"${currentPath}/../core/script/run.sh" "install,webServer:single,database" "${currentPath}/urls/database.sh" \
  --adminHostName "${adminHostName}"
"${currentPath}/../core/script/run.sh" "install,webServer:single,host:all,database" "${currentPath}/urls/database-host.sh"


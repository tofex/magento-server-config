#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mainHostName=$("${currentPath}/../core/server/host/single.sh")

"${currentPath}/../core/script/run.sh" "install,database" "${currentPath}/urls/database.sh" \
  --mainHostName "${mainHostName}"
"${currentPath}/../core/script/run.sh" "install,host:all,database" "${currentPath}/urls/database-host.sh"

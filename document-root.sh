#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "install,config,webServer:all" "${currentPath}/document-root/config.sh"

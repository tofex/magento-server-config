#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "config,install,redisFPC,webServer" "${currentPath}/redis-fpc/config.sh"

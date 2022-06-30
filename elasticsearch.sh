#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "database" "${currentPath}/elasticsearch/database.sh"
"${currentPath}/../core/script/run.sh" "config,install,elasticsearch,webServer" "${currentPath}/elasticsearch/config.sh"

#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

randomPrefix=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
echo "Adding random prefix: ${randomPrefix} to all entity increment ids"

"${currentPath}/../core/script/run.sh" "install,database" "${currentPath}/prefix/database.sh" \
 --prefix "${randomPrefix}"

#!/usr/bin/env bash

set -euo pipefail

save_function() {
    local ORIG_FUNC=$(declare -f $1)
    local NEWNAME_FUNC="$2${ORIG_FUNC#$1}"
    eval "$NEWNAME_FUNC"
}

# Sets an argument to be consumed by the arg shift in the ${ORIGINAL_HOOK}
set -- __dummy_arg_does_not_exist__ "$@"

. "${ORIGINAL_HOOK}"

save_function deploy_cert __original_deploy_cert
function deploy_cert {
    __original_deploy_cert "$@"
    echo " + Reloading Services"
    "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/reload_services.sh" "$@"
}

HANDLER=$1; shift;
if [ -n "$(type -t $HANDLER)" ] && [ "$(type -t $HANDLER)" = function ]; then
  $HANDLER "$@"
fi


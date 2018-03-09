#!/bin/bash

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd -P )"

"$@"
if [[ -z $PIN_DISABLE_AUTO_RETRY && $? -ne 0 ]]; then
  "$1" clean
  "$@"
fi

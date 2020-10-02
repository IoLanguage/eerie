#!/bin/sh

io setup.io "$@"

export EERIEDIR=$(cat __install_path)
export PATH="$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin"

rm -f __install_path

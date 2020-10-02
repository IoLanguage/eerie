#!/bin/sh

io setup.io "$@"

export EERIEDIR=#{eeriePath}
export PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin

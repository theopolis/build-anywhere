#!/usr/bin/env bash

if [[ ! "x$0" = "x-bash" ]]
        then BASH_SOURCE=$0
fi

SCRIPT=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$SCRIPT")
INSTALLPATH=$(dirname "$SCRIPTPATH")

EXTRA_CFLAGS="-fPIC -g -fsanitize=address -fno-omit-frame-pointer -fsanitize-coverage=edge,indirect-calls,trace-cmp,trace-div,trace-gep"
EXTRA_LDFLAGS="-fuse-ld=lld"

. $SCRIPTPATH/anywhere-setup.sh "$EXTRA_LDFLAGS" "$EXTRA_CFLAGS"

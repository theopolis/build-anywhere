#!/usr/bin/env bash

if [[ ! "x$0" = "x-bash" ]]
        then BASH_SOURCE=$0
fi

SCRIPT=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$SCRIPT")
INSTALLPATH=$(dirname "$SCRIPTPATH")

EXTRA_CFLAGS="-fPIC -fPIE -fstack-protector-all -fsanitize=safe-stack"
# -O3 -flto

EXTRA_LDFLAGS="-fuse-ld=lld -Wl,-z,relro,-z,now -pie"
# -flto

. $SCRIPTPATH/anywhere-setup.sh "$EXTRA_LDFLAGS" "$EXTRA_CFLAGS"

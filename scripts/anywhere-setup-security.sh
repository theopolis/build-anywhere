#!/usr/bin/env sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

EXTRA_CFLAGS="-fPIC -fPIE -pie -fstack-protector-all -fsanitize=safe-stack"
EXTRA_LDFLAGS="-Wl,-z,relro -Wl,-z,now"

. $SCRIPTPATH/setup.sh "$EXTRA_LDFLAGS" "$EXTRA_CFLAGS"


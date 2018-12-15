#!/usr/bin/env sh

[ "x$SYSROOT" = x""]; echo "Cannot find SYSROOT environment" && exit 1

GLIBC_214=$(find $SYSROOT/usr/lib -type f | grep "\.so"  | xargs objdump -p  2>&1| grep GLIBC_2.14)

[ ! "x$GLIBC_214" = x"" ]; echo "Found glibc 2.14 required" && exit 1


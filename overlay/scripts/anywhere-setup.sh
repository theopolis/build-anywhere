#!/usr/bin/env bash

if [[ "x$BASH_SOURCE" = x"" ]]
        then BASH_SOURCE=$0
fi

SCRIPT=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$SCRIPT")
INSTALLPATH=$(dirname "$SCRIPTPATH")

SYSROOT="${INSTALLPATH}/x86_64-anywhere-linux-gnu/sysroot"
PREFIX="${SYSROOT}/usr"

NEW_PATH="${PREFIX}/bin:${SYSROOT}/sbin"
case ":${PATH:=$NEW_PATH}:" in
    *:${NEW_PATH}:*)  ;;
    *) PATH="${NEW_PATH}:${PATH}"  ;;
esac

export PATH="${PATH}"
export CC="clang"
export CXX="clang++"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export LIBRARY_PATH="${PREFIX}/lib"
export LDFLAGS="-static-libgcc $1 -fuse-ld=lld -Wl,-z,relro,-z,now -pie -l:libc++.a -l:libc++abi.a -l:libunwind.a -lpthread -ldl -lrt -lz -lm"
export CPPFLAGS="--gcc-toolchain=${INSTALLPATH} --sysroot=${SYSROOT}"
export CFLAGS="${CPPFLAGS} -march=x86-64 -fPIC -Oz $2"
export CXXFLAGS="${CFLAGS} -stdlib=libc++"

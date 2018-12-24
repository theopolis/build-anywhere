#!/usr/bin/env bash

if [[ "x$BASH_SOURCE" = x"" ]]
        then BASH_SOURCE=$0
fi

SCRIPT=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$SCRIPT")
INSTALLPATH=$(dirname "$SCRIPTPATH")

SYSROOT=$INSTALLPATH/x86_64-anywhere-linux-gnu/sysroot
PREFIX=$SYSROOT/usr

NEW_PATH=$PREFIX/bin:$SYSROOT/sbin
case ":${PATH:=$NEW_PATH}:" in
    *:$NEW_PATH:*)  ;;
    *) PATH="$NEW_PATH:$PATH"  ;;
esac

export PATH=$PATH
export PREFIX=$PREFIX
export CC="clang --gcc-toolchain=$INSTALLPATH --sysroot=$SYSROOT"
export CXX="clang++ --gcc-toolchain=$INSTALLPATH --sysroot=$SYSROOT"
export CONFIG_SITE=$INSTALLPATH/config.site
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export LIBRARY_PATH=$PREFIX/lib
export LDFLAGS="-static-libgcc -static-libstdc++ $1 -l:libc++.a -l:libc++abi.a -l:libunwind.a"
export CFLAGS="--gcc-toolchain=$INSTALLPATH --sysroot=$SYSROOT -march=x86-64 $2"
export CXXFLAGS="$CFLAGS -stdlib=libc++"

echo "prefix=$PREFIX" > $INSTALLPATH/config.site

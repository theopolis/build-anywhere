#!/usr/bin/env sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

SYSROOT=$SCRIPTPATH/x86_64-anywhere-linux-gnu/sysroot
PREFIX=$SYSROOT/usr

NEW_PATH=$PREFIX/bin:$SYSROOT/sbin
case ":${PATH:=$NEW_PATH}:" in
    *:$NEW_PATH:*)  ;;
    *) PATH="$NEW_PATH:$PATH"  ;;
esac

export PATH=$PATH
export PREFIX=$PREFIX
export CC="clang --gcc-toolchain=$SCRIPTPATH --sysroot=$SYSROOT"
export CXX="clang++ --gcc-toolchain=$SCRIPTPATH --sysroot=$SYSROOT"
export CONFIG_SITE=$SCRIPTPATH/config.site
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export LDFLAGS="-static-libgcc -static-libstdc++ $1"
export CFLAGS="-DNDEBUG -march=x86-64 $2"
export CXXFLAGS="$CFLAGS"

echo "prefix=$PREFIX" > $SCRIPTPATH/config.site

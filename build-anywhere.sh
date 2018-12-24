#!/usr/bin/env bash

set -e

DIR=$1
TUPLE=x86_64-anywhere-linux-gnu
SYSROOT=$DIR/$TUPLE/$TUPLE/sysroot
PREFIX=$SYSROOT/usr

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

ZLIB_VER="1.2.11"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VER}.tar.gz"
ZLIB_SHA="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"

LIBXML2_VER="2.9.7"
LIBXML2_URL="http://xmlsoft.org/sources/libxml2-${LIBXML2_VER}.tar.gz"
LIBXML2_SHA="f63c5e7d30362ed28b38bfa1ac6313f9a80230720b7fb6c80575eeab3ff5900c"

mkdir -p $DIR

# Clone and build CrosstoolNG.
if [[ ! -d $DIR/crosstool-ng ]]; then
  ( cd $DIR; \
    git clone https://github.com/crosstool-ng/crosstool-ng )
fi

# Use our own config that sets a legacy glibc.
cp $SCRIPT_DIR/config $DIR/crosstool-ng/.config

if [[ ! -f $DIR/crosstool-ng/ct-ng ]]; then
  ( cd $DIR/crosstool-ng; \
    ./bootstrap; \
    ./configure --enable-local; \
    make )
fi

# Build toolchain.
if [[ ! -e $PREFIX/bin/gcc ]]; then
  ( cd $DIR/crosstool-ng;
    CT_PREFIX=$DIR ./ct-ng build )

  # Create symlinks in the new sysroot to GCC.
  ( cd $PREFIX/bin; \
    for file in ../../../../bin/*; do ln -s $file ${file/*${TUPLE}-/} || true; done )
  ( cd $PREFIX/lib; \
    for file in ../../lib/libstdc*; do ln -s $file $(basename $file) || true; done )
fi

export PATH=$PREFIX/bin:$PATH

# Build a legacy zlib and install into the sysroot.
if [[ ! -d $DIR/zlib-${ZLIB_VER} ]]; then
  ( cd $DIR; \
    wget $ZLIB_URL; \
    echo "${ZLIB_SHA} zlib-${ZLIB_VER}.tar.gz" | sha256sum -c; \
    tar xzf zlib-${ZLIB_VER}.tar.gz )
fi

if [[ ! -e $PREFIX/lib/libz.a ]]; then
  ( cd $DIR/zlib-${ZLIB_VER}; \
    ./configure --prefix $PREFIX;
    make; \
    make install )
fi

# Build a new libxml and install (static only) into the sysroot.
if [[ ! -d $DIR/libxml2-${LIBXML2_VER} ]]; then
  ( cd $DIR; \
    wget $LIBXML2_URL; \
    echo "${LIBXML2_SHA} libxml2-${LIBXML2_VER}.tar.gz" | sha256sum -c; \
    tar xzf libxml2-${LIBXML2_VER}.tar.gz )
fi

if [[ ! -e $PREFIX/lib/libxml2.a ]]; then
  ( cd $DIR/libxml2-${LIBXML2_VER}; \
    ./configure --with-pic --prefix $PREFIX --enable-static --without-lzma --without-python; \
    make; \
    make install )
fi

# Fix some libxml symlinks.
if [[ ! -e $PREFIX/include/libxml ]]; then
  ( cd $PREFIX/include; \
    ln -s libxml2/libxml libxml )
fi

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

# Build LLVM twice.
unset OPT
if [[ -e $PREFIX/src/llvm ]]; then
  rm -rf $PREFIX/src/llvm/build*
  OPT=-c
fi

CC=gcc CXX=g++ $SCRIPT_DIR/install-clang.sh $OPT -j 6 -t $DIR/$TUPLE -s $SYSROOT $PREFIX

# Remove the static libclang/liblld/libLLVM libraries from the sysroot.
( cd $PREFIX/lib; \
  ls | grep -e "libclang.*a" | xargs rm; \
  ls | grep -e "liblld.*a" | xargs rm; \
  ls | grep -e "libLLVM.*a" | xargs rm )

# Remove shared versions of libc++ and libunwind.
( cd $PREFIX/lib; \
  rm libc++*.so*; \
  rm libunwind*.so* )

# Install our helper / debugging scripts.
cp -R $SCRIPT_DIR/overlay/* $DIR/$TUPLE

echo "Complete"

#!/usr/bin/env bash

set -e

DIR=$1
TUPLE=x86_64-anywhere-linux-gnu
SYSROOT=$DIR/$TUPLE/$TUPLE/sysroot
PREFIX=$SYSROOT/usr

mkdir -p $DIR

# Clone and build CrosstoolNG.
if [[ ! -d $DIR/crosstool-ng ]]; then
  ( cd $DIR; \
    git clone https://github.com/crosstool-ng/crosstool-ng )
fi

# Use our own config that sets a legacy glibc.
cp config $DIR/crosstool-ng/.config

if [[ ! -f $DIR/crosstool-ng/ct-ng ]]; then
  ( cd $DIR/crosstool-ng; \
    ./bootstrap; \
    ./configure --enable-local; \
    make )
fi

( cd $DIR/crosstool-ng;
  CT_PREFIX=$DIR ./ct-ng build )

# Create symlinks in the new sysroot to GCC.
if [[ ! -e $PREFIX/bin/gcc ]]; then
  ( cd $PREFIX/bin; \
    for file in ../../../../bin/*; do ln -s $file ${file/*${TUPLE}-/} || true; done )
fi

export PATH=$PREFIX/bin:$PATH

# Build a legacy zlib and install into the sysroot.
if [[ ! -d $DIR/zlib-1.2.11 ]]; then
  cp zlib-1.2.11.tar.gz $DIR
  ( cd $DIR; \
    tar xzf zlib-1.2.11.tar.gz )
fi

( cd $DIR/zlib-1.2.11; \
  ./configure --prefix $PREFIX;
  make; \
  make install )

# Build a new libxml and install (static only) into the sysroot.
if [[ ! -d $DIR/libxml2-2.9.7 ]]; then
  cp libxml2-2.9.7.tar.gz $DIR
  ( cd $DIR; \
    tar xzf libxml2-2.9.7.tar.gz )
fi

( cd $DIR/libxml2-2.9.7; \
  ./configure --with-pic --prefix $PREFIX --enable-static --without-lzma --without-python; \
  make; \
  make install )

# Fix some libxml symlinks.
if [[ ! -e $PREFIX/include/libxml ]]; then
  ( cd $PREFIX/include; \
    ln -s libxml2/libxml libxml )
fi

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

# Build LLVM twice.
unset OPT
if [[ -e $DIR/src/llvm ]]; then
  OPT=-c
fi

CC=gcc CXX=g++ ./install-clang.sh $OPT -j 6 -t $DIR/$TUPLE -s $SYSROOT $PREFIX

# Remove the static libclang/liblld/libLLVM libraries from the sysroot.
( cd $PREFIX/lib; \
  ls | grep -e "libclang.*a" | xargs rm; \
  ls | grep -e "liblld.*a" | xargs rm; \
  ls | grep -e "libLLVM.*a" | xargs rm )

echo "Complete"

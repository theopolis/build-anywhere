#!/usr/bin/env bash

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

LATEST=$(git describe --abbrev=0 --tags)
BUNDLE="x86_64-anywhere-linux-gnu-${LATEST}.tar.xz"
BUNDLE_URL="https://github.com/theopolis/build-anywhere/releases/download/${LATEST}/${BUNDLE}"

SSDEEP_VER="2.14.1"
SSDEEP_URL="https://github.com/ssdeep-project/ssdeep/releases/download/release-${SSDEEP_VER}/ssdeep-${SSDEEP_VER}.tar.gz"

OPENSSL_VER="1.0.2o"
OPENSSL_URL="https://dl.bintray.com/homebrew/mirror/openssl-${OPENSSL_VER}.tar.gz"

function setup {
  wget $BUNDLE_URL
  tar xf $BUNDLE
  cp -R $SCRIPTPATH/../overlay x86_64-anywhere-linux-gnu/
}

function build_openssl {
  DIR="openssl-${OPENSSL_VER}"
  if [[ -d $DIR ]]; then
    rm -rf $DIR*
  fi
  wget $OPENSSL_URL
  tar xf openssl-${OPENSSL_VER}.tar.gz
  (cd $DIR; \
    ./Configure --prefix=$PREFIX \
      no-ssl3 no-asm no-weak-ssl-ciphers zlib-dynamic no-shared linux-x86_64 \
      "$CFLAGS -Wno-unused-command-line-argument" "$LDFLAGS";
    make -j$(nproc); \
    make install)

  if [[ -f "$PREFIX/lib/libssl.so*" ]]; then
    exit 1
  fi

  if [[ ! -f "$PREFIX/lib/libssl.a" ]]; then
    exit 1
  fi
}

function build_ssdeep {
  DIR="ssdeep-${SSDEEP_VER}"
  if [[ -d $DIR ]]; then
    rm -rf $DIR*
  fi
  wget $SSDEEP_URL
  tar xf ssdeep-${SSDEEP_VER}.tar.gz
  (cd $DIR; \
    ./configure --disable-shared; \
    make -j$(nproc); \
    make install)

  if [[ ! -f "$PREFIX/lib/libfuzzy.a" ]]; then
    exit 1
  fi
}

setup

# Try the normal build

source x86_64-anywhere-linux-gnu/scripts/anywhere-setup.sh

build_openssl
build_ssdeep

source x86_64-anywhere-linux-gnu/scripts/anywhere-setup-security.sh

build_openssl
build_ssdeep

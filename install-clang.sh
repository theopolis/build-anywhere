#!/usr/bin/env bash

set -e

triple=$(gcc -v 2>&1 | grep "^Target:" | cut -d ' ' -f 2)
addl_ldflags="-Wl,--strip-all -ldl -lz"
addl_cmake="-DLLVM_DEFAULT_TARGET_TRIPLE=${triple}"

shopt -s nullglob

perform_clone=1
assertions=off
parallelism=1
targets=host
toolchain=none
sysroot=none
v=7.0.0

while getopts "j:t:s:c" opt ; do
    case "$opt" in
        c)
            perform_clone=0
            ;;
        j)
            parallelism=$OPTARG
            ;;
        t)
            toolchain=$OPTARG
            ;;
        s)
            sysroot=$OPTARG
            ;;
    esac
done

shift $(expr $OPTIND - 1)
prefix=`echo $1 | sed 's#/$##'`
shift

if [ ! -d $prefix ]; then
    if ! mkdir -p $prefix; then
        echo failed to create directory $prefix
        exit 1
    fi
fi

#### Set paths and environment.

unset CFLAGS
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS
unset LD_LIBRARY_PATH
unset DYLD_LIBRARY_PATH

# Built libraries with RTTI.
export REQUIRES_RTTI=1
export PATH=$prefix/bin:$PATH

src="$prefix/src/llvm"

libcxx_include=$prefix/include/c++/v1
mkdir -p $libcxx_include

if [ "${perform_clone}" == "1" ]; then

    mkdir -p `dirname $src`
    echo Changing directory to `dirname $src` for installing  ...
    cd `dirname $src`

    if [[ ! -d ${src}/tools/clang ]]; then
        wget http://releases.llvm.org/${v}/llvm-${v}.src.tar.xz
        tar xf llvm-${v}.src.tar.xz && mv llvm-${v}.src llvm

        wget http://releases.llvm.org/${v}/cfe-${v}.src.tar.xz
        tar xf cfe-${v}.src.tar.xz && mv cfe-${v}.src llvm/tools/clang

        wget http://releases.llvm.org/${v}/libcxx-${v}.src.tar.xz
        tar xf libcxx-${v}.src.tar.xz && mv libcxx-${v}.src llvm/projects/libcxx

        wget http://releases.llvm.org/${v}/compiler-rt-${v}.src.tar.xz
        tar xf compiler-rt-${v}.src.tar.xz && mv compiler-rt-${v}.src llvm/projects/compiler-rt

        wget http://releases.llvm.org/${v}/libunwind-${v}.src.tar.xz
        tar xf libunwind-${v}.src.tar.xz && mv libunwind-${v}.src llvm/projects/libunwind

        wget http://releases.llvm.org/${v}/libcxxabi-${v}.src.tar.xz
        tar xf libcxxabi-${v}.src.tar.xz && mv libcxxabi-${v}.src llvm/projects/libcxxabi

        wget http://releases.llvm.org/${v}/clang-tools-extra-${v}.src.tar.xz
        tar xf clang-tools-extra-${v}.src.tar.xz && mv clang-tools-extra-${v}.src llvm/tools/clang/extra

        wget http://releases.llvm.org/${v}/lld-${v}.src.tar.xz
        tar xf lld-${v}.src.tar.xz && mv lld-${v}.src llvm/tools/lld
    fi
fi

CMAKE_common="-DLLVM_BUILD_LLVM_DYLIB=on"
CMAKE_common="${CMAKE_common} -DLLVM_LINK_LLVM_DYLIB=on"
CMAKE_common="${CMAKE_common} -DLLVM_ENABLE_EH=on"
CMAKE_common="${CMAKE_common} -DLLVM_ENABLE_RTTI=on"
CMAKE_common="${CMAKE_common} -DLLVM_TARGETS_TO_BUILD=X86;ARM;AArch64"
CMAKE_common="${CMAKE_common} -DLLDB_DISABLE_PYTHON=on"
CMAKE_common="${CMAKE_common} -DLLVM_INCLUDE_DOCS=off"
CMAKE_common="${CMAKE_common} -DLLVM_INCLUDE_TESTS=off"
CMAKE_common="${CMAKE_common} -DLLVM_INCLUDE_EXAMPLES=off"

CMAKE_stage0="${CMAKE_common} -DLLVM_TOOL_LLD_BUILD=on"
CMAKE_stage0="${CMAKE_stage0} -DLLVM_TOOL_LLDB_BUILD=off"

echo Building LLVM/clang, stage 0 ...

( cd $src && \
  mkdir -p build-stage0 && \
  cd build-stage0 && \
  CC="$CC" \
  CXX="$CXX" \
  CFLAGS="-Os -s" \
  CXXFLAGS="-Os -s" \
  LDFLAGS="${addl_ldflags}" \
  cmake -DCMAKE_BUILD_TYPE=${buildtype} \
        -DLLVM_REQUIRES_RTTI=1 \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        ${addl_cmake} \
        ${CMAKE_stage0} \
        .. && \
  make -j $parallelism VERBOSE=1 V=1 && \
  make install \
)

echo Building LLVM/clang, stage 1 ...

CMAKE_libcpp="-DLIBCXX_USE_COMPILER_RT=on"
CMAKE_libcpp="${CMAKE_libcpp} -DLIBCXXABI_USE_COMPILER_RT=on"
CMAKE_libcpp="${CMAKE_libcpp} -DLIBCXXABI_USE_LLVM_UNWINDER=on"
CMAKE_libcpp="${CMAKE_libcpp} -DLLVM_BUILD_EXTERNAL_COMPILER_RT=on"

CMAKE_stage1="${CMAKE_common} ${CMAKE_libcpp}"
CMAKE_stage1="${CMAKE_stage1} -DGCC_INSTALL_PREFIX=${sysroot}/usr"
CMAKE_stage1="${CMAKE_stage1} -DCMAKE_SYSROOT=${sysroot}"
CMAKE_stage1="${CMAKE_stage1} -DLLVM_ENABLE_LLD=on"

( cd $src && \
  mkdir -p build-stage1/projects && \
  cd build-stage1/projects && \
  CC=$prefix/bin/clang \
  CXX=$prefix/bin/clang++ \
  CFLAGS="-Os --sysroot=${sysroot} --gcc-toolchain=${toolchain}" \
  CXXFLAGS="-Os --sysroot=${sysroot} --gcc-toolchain=${toolchain}" \
  LDFLAGS="${addl_ldflags} -lunwind -rtlib=compiler-rt -fuse-ld=lld" \
  cmake -DCMAKE_BUILD_TYPE=${buildtype} \
        -DLLVM_REQUIRES_RTTI=1 \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        ${addl_cmake} \
        ${CMAKE_stage1} \
        ../.. && \
  cd projects && \
  make -j $parallelism VERBOSE=1 V=1 && \
  make install \
)

echo Deleting $src ...
rm -rf "${src}"
rm -rf "${src}/../*"

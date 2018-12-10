#! /usr/bin/env bash

triple=$(gcc -v 2>&1 | grep "^Target:" | cut -d ' ' -f 2)
addl_ldflags="-Wl,--strip-all -ldl -lz -lunwind"
addl_cmake="-DLLVM_DEFAULT_TARGET_TRIPLE=${triple}"

shopt -s nullglob

perform_clone=1
assertions=off             # If "on", enable LLVM assertions.
parallelism=1              # The value X to pass to make -j X to build in parallel.
targets=host               # LLVM_TARGETS_TO_BUILD ("all" builds them all).
git_base=https://github.com/llvm-mirror
toolchain=none
sysroot=none

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

# git version to checkout.
version_llvm=release_60
version_clang=release_60
version_libcxx=release_60
version_compilerrt=release_60
version_libcxxabi=release_60
# version_lldb=release_60
version_lld=release_60
version_extra=release_60
version_libunwind=release_60

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
src_libcxxabi=${src}/projects/libcxxabi
src_libcxx=${src}/projects/libcxx
src_compilerrt=${src}/projects/compiler-rt
src_libunwind=${src}/projects/libunwind
# src_lldb=${src}/tools/lldb
src_lld=${src}/tools/lld
libcxx_include=$prefix/include/c++/v1
libcxx_lib=$prefix/lib

mkdir -p $libcxx_include

function st
{
    eval echo \$\{$1_stage${stage}\}
}

function apply_patch
{
    patch=$1
    base=`basename $patch`

    cwd=`pwd`

    cd $src

    if basename "$patch" | grep -q -- '--'; then
        dir=`echo $base | awk -v src=$src -F '--' '{printf("%s/%s/%s", src, $1, $2);}'`
        if [ ! -d "$dir" ]; then
            return
        fi

        cd $dir
    fi

    cat $patch | git am -3
}

#### Clone reposistories.

export GIT_COMMITTER_EMAIL="`whoami`@localhost"
export GIT_COMMITTER_NAME="`whoami`"

d=`dirname $0`
patches=`cd $d; pwd`/patches

if [ "${perform_clone}" == "1" ]; then

    mkdir -p $src
    echo Changing directory to `dirname $src` for installing  ...
    cd `dirname $src`

    if [[ ! -d `basename $src`/.git ]]; then
        git clone ${git_base}/llvm.git `basename $src`

        ( cd $src/tools && git clone ${git_base}/clang.git )
        ( cd $src/projects && git clone ${git_base}/libcxx )
        ( cd $src/projects && git clone ${git_base}/compiler-rt )
        ( cd $src/projects && git clone ${git_base}/libunwind )

        ( cd $src && git checkout -q ${version_llvm} )
        ( cd $src/tools/clang && git checkout -q ${version_clang}  )
        ( cd ${src_libcxx} && git checkout -q ${version_libcxx} )
        ( cd ${src_compilerrt} && git checkout -q ${version_compilerrt} )
        ( cd ${src_libunwind} && git checkout -q ${version_libunwind} )

        ( cd $src/projects && git clone ${git_base}/libcxxabi )
        ( cd ${src_libcxxabi} && git checkout -q ${version_libcxxabi} )

        ( cd $src/tools/clang/tools && git clone ${git_base}/clang-tools-extra.git extra )
        ( cd $src/tools/clang/tools/extra && git checkout -q ${version_extra} )

        ( cd `dirname ${src_lld}` && git clone ${git_base}/lld `basename ${src_lld}`)
        ( cd ${src_lld} && git checkout -q ${version_lld}  )
    fi

    # Cherry pick additional commits from master.
    echo "${cherrypick}" | awk -v RS=\; '{print}' | while read line; do
        if [ "$line" != "" ]; then
            repo=`echo $line | cut -d ' ' -f 1`
            commits=`echo $line | cut -d ' ' -f 2-`
            echo "Cherry-picking $commits in $repo"
            ( cd ${src}/$repo \
              && git cherry-pick --strategy=recursive -X theirs $commits )
        fi
    done

    # Apply any patches we might need.
    for i in $patches/*; do
        apply_patch $i
    done

    echo === Done applying patches
fi

CMAKE_common="-DLLVM_BUILD_LLVM_DYLIB=on -DLLVM_LINK_LLVM_DYLIB=on -DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=on -DLLVM_TARGETS_TO_BUILD=X86;ARM;AArch64"
CMAKE_common="${CMAKE_common} -DLLDB_DISABLE_PYTHON=on -DLLVM_INCLUDE_DOCS=off -DLLVM_INCLUDE_TESTS=off -DLLVM_INCLUDE_EXAMPLES=off"

CMAKE_stage0="${CMAKE_common} -DLLVM_TOOL_LLD_BUILD=on -DLLVM_TOOL_LLDB_BUILD=off"
#CMAKE_stage0="${CMAKE_stage0} \"-DCMAKE_EXE_LINKER_FLAGS=-ldl -lz\" \"-DCMAKE_SHARED_LINKER_FLAGS=-ldl -lz\""

CMAKE_libcpp="-DLLVM_TOOL_LIBCXX_BUILD=on -DLLVM_TOOL_LIBCXXABI_BUILD=on -DLLVM_TOOL_COMPILER_RT_BUILD=on"
CMAKE_libcpp="${CMAKE_libcpp} -DLIBCXX_USE_COMPILER_RT=on -DLIBCXXABI_USE_COMPILER_RT=on -DLIBCXXABI_USE_LLVM_UNWINDER=on"

CMAKE_stage1="${CMAKE_common} ${CMAKE_stage1} -DLLVM_ENABLE_ASSERTIONS=${assertions} ${CMAKE_libcpp}"
CMAKE_stage1="$PCMAKE_stage1} -DGCC_INSTALL_PREFIX=${sysroot}/usr -DCMAKE_SYSROOT=${sysroot}"
CMAKE_stage1="${CMAKE_stage1} -DLLVM_TOOL_LLD_BUILD=on -DLLVM_TOOL_LLDB_BUILD=off -DLLVM_ENABLE_LLD=on"

#### Configure the stages.

# Stage 0 options. Get us a clang.

CC_stage0="$CC"
CXX_stage0="$CXX"
CFLAGS_stage0="-Os -s"
CXXFLAGS_stage0="-Os -s"
LDFLAGS_stage0="${addl_ldflags}"
BUILD_TYPE_stage0=${buildtype}

# Stage 1 options. Compile against standard libraries.

CC_stage1=$prefix/bin/clang
CXX_stage1=$prefix/bin/clang++

CFLAGS_stage1="-Os --sysroot=${sysroot} --gcc-toolchain=${toolchain}"
CXXFLAGS_stage1="-Os --sysroot=${sysroot} --gcc-toolchain=${toolchain}"
LDFLAGS_stage1="${addl_ldflags} -rtlib=compiler-rt -fuse-ld=lld"
BUILD_TYPE_stage1=${buildtype}

#### Compile the stages.

echo Changing directory to $src ...
cd $src

for stage in 0 1; do
     echo ===
     echo === Building LLVM/clang, stage ${stage} ...
     echo ===

     ( cd $src && \
       mkdir -p build-stage${stage} && \
       cd build-stage${stage} && \
       CC=`st CC` \
       CXX=`st CXX` \
       CFLAGS="`st CFLAGS`" \
       CXXFLAGS="`st CXXFLAGS`" \
       LDFLAGS="`st LDFLAGS`" \
       cmake -DCMAKE_BUILD_TYPE=`st BUILD_TYPE` \
             -DLLVM_REQUIRES_RTTI=1 \
             -DCMAKE_INSTALL_PREFIX=${prefix} \
             ${addl_cmake} \
             `st CMAKE` \
             .. && \
       make -j $parallelism VERBOSE=1 V=1 && \
       make install \
     )

    if [ "$?" != "0" ] ; then
        echo ===
        echo === Failed building LLVM/clang at stage ${stage}
        echo ===
        exit 1
    fi
done

echo Deleting $src ...
rm -rf "${src}"

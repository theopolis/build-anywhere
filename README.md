# ./build-anywhere.sh /output/path

[![Build Status](https://travis-ci.org/theopolis/build-anywhere.svg?branch=master)](https://travis-ci.org/theopolis/build-anywhere)

These scripts build a toolchain/runtime that runs on almost every Linux distribution. The compilers can produce libraries and executables that also run on almost every Linux distribution.

> anywhere (n). x86_64 Linux distributions that include a 2.13 (circa 2011+) or newer glibc.

At a very high level:

- Use Crosstool-NG to build **gcc 8.2.0** linked against a **glibc 2.13**.
- Build an older **zlib 1.2.11** to link against.
- Build **Clang/LLVM 8.0.0** with the new GCC also linked against a **glibc 2.13**.
- You can use the clang/gcc compiler anywhere.
- You can use either clang or gcc's compiler runtime; recommend using linking flags to link these statically.
- You can use either libstdc++ or libc++; recommended linking these statically.
- You can use all of the LLVM static analysis and sanitizer frameworks.

This project builds the runtime. You can download pre-built runtimes on the [Releases](https://github.com/theopolis/build-anywhere/releases) page.

## man build-anywhere.sh

### build-from-source

```
$ ./build-anywhere.sh /opt/build
```

This will create several output files/directories in `/opt/build`, at the end the important one is `x86_64-anywhere-linux-gnu`.

```
$ du -h --max-depth=2 /opt/build/x86_64-anywhere-linux-gnu
44M   /opt/build/x86_64-anywhere-linux-gnu/bin
4.0K  /opt/build/x86_64-anywhere-linux-gnu/include
54M   /opt/build/x86_64-anywhere-linux-gnu/libexec/gcc
54M   /opt/build/x86_64-anywhere-linux-gnu/libexec
4.0K  /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/bin
11M   /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/include
48K   /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/lib64
710M  /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/sysroot
4.0K  /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/lib
4.0K  /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/debug-root
720M  /opt/build/x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu
1.5M  /opt/build/x86_64-anywhere-linux-gnu/lib/ldscripts
9.8M  /opt/build/x86_64-anywhere-linux-gnu/lib/gcc
12M   /opt/build/x86_64-anywhere-linux-gnu/lib
120K  /opt/build/x86_64-anywhere-linux-gnu/share/gcc-8.2.0
1.7M  /opt/build/x86_64-anywhere-linux-gnu/share/licenses
1.8M  /opt/build/x86_64-anywhere-linux-gnu/share
831M  /opt/build/x86_64-anywhere-linux-gnu
```

**Remember** you can build this once and run it from any directory on any x86_64 Linux created in 2011 or newer.

### download-prebuilt

You can also download a prebuilt version, [`x86_64-anywhere-linux-gnu-VERSION.tar.gz`](https://github.com/theopolis/build-anywhere/releases), from the GitHub releases page.

You can untar this and run from any directory. See below for guidance on how to use the toolchain.

## Using the anywhere toolchain

Sourcing the `./scripts/anywhere-setup.sh` script should set up your environment.

```
source ./x86_64-anywhere-linux-gnu/scripts/anywhere-setup.sh
```

Important variables:

```
SYSROOT=x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/sysroot
PATH=$PREFIX/bin:$PATH
CXX=clang++
CC=clang
```

There are several optional variables you may want to include. If you intend to install into the build-anywhere toolchain, also set the following:

```
PREFIX=$SYSROOT/usr
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ACLOCAL_PATH=$PREFIX/share/aclocal
```

## (Somewhat) security-enhanced toolchain

Source the `./scripts/anywhere-setup-security.sh` script adds extra linker and compiler flags.

```
source ./x86_64-anywhere-linux-gnu/scripts/anywhere-setup-security.sh
```

## Accuracy

There are some excessive linking options included.

```
-fuse-ld=lld -Wl,-z,relro,-z,now -pie -l:libc++.a -l:libc++abi.a -l:libunwind.a -lpthread -ldl -lrt -lz -lm
```

And the compiler flags attempt to make small binaries, with PIC, and without newer ASM.

```
-march=x86-64 -fPIC -Oz
```

This is a best-effort solution that covers most bases. Every project's build system is different and may not respect the variable this toolchain sets. Most problems can be resolved by telling autotools, cmake, etc, system about the explicit linking and include paths.

As an example, SleuthKit will still find the system `libstdc++.so` and OpenSSL needs an explicit `--prefix=$PREFIX`.

A more-accurate version forces the use of clang, clang's compiler runtime, and LLVM's `libc++`. This is more accurate because it is harder for build systems to work if they make assumptions (e.g., we did not read their documentation closely). So you either break it or it works, which is better. The side effect of this is about 100kB additional code from static linking compared to gcc's runtime and c++ implementation.

You can also remove the libc dynamic libraries to force anything trying to link them statically.
- `$PREFIX/lib/libc++*.so*`
- `$PREFIX/lib/libunwind*.so*`

Now build systems have no choice.

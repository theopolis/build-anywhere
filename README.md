# ./build-anywhere.sh /output/path

These scripts build a toolchain/runtime that runs on almost every Linux distribution. The compilers can product libraries and executables that also run on almost every Linux distribution.

> anywhere (n). x86_64 Linux distributions that include a 2.13 (cs 2011) or newer glibc.

At a very high level:

- Use Crosstool-NG to build a new GCC linked against a 2.13 glibc.
- Build an older zlib to link against.
- Build a new Clang/LLVM with the new GCC also linked against a 2.13 glibc.

## man build-anywhere.sh

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

You can also download a `x86_64-anywhere-linux-gnu.tar.gz` if someone is kind enough to host it. **Remember** you can build this once and hopefully run it from any directory on any x86_64 Linux created in 2011 or later.

## Using the anywhere toolchain

Sourcing the `anywhere-setup.sh` script should set up your environment.

```
. /x86_64-anywhere-linux-gnu/anywhere-setup.sh
```

Important variables:

```
SYSROOT=x86_64-anywhere-linux-gnu/x86_64-anywhere-linux-gnu/sysroot
PREFIX=$SYSROOT/usr
PATH=$PREFIX/bin:$PATH
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
CXX=clang++ --sysroot=$SYSROOT --gcc-toolchain=x86_64-anywhere-linux-gnu
CC=clang --sysroot=$SYSROOT --gcc-toolchain=x86_64-anywhere-linux-gnu
```

## (Somewhat) security-enhanced toolchain

Source the `anywhere-setup-security.sh` script adds extra linker and compiler flags.

```
. x86_64-anywhere-linux-gnu/anywhere-setup=security.sh
```

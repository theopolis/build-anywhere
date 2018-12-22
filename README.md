# ./build-anywhere.sh /output/path

These scripts build a toolchain/runtime that runs on almost every Linux distribution. The compilers can produce libraries and executables that also run on almost every Linux distribution.

> anywhere (n). x86_64 Linux distributions that include a 2.13 (circa 2011+) or newer glibc.

At a very high level:

- Use Crosstool-NG to build **gcc 8.2.0** linked against a **glibc 2.13**.
- Build an older **zlib 1.2.11** to link against.
- Build **Clang/LLVM 7.0.0** with the new GCC also linked against a **glibc 2.13**.
- You can use the clang/gcc compiler anywhere.
- You can use either clang or gcc's compiler runtime; recommend using linking flags to link these statically.
- You can use either libstdc++ or libc++; recommended linking these statically.
- You can use all of the LLVM static analysis and sanitizer frameworks.

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

You can also download a `x86_64-anywhere-linux-gnu.tar.gz` if someone is kind enough to host it. **Remember** you can build this once and run it from any directory on any x86_64 Linux created in 2011 or newer.

## Using the anywhere toolchain

Sourcing the `./scripts/anywhere-setup.sh` script should set up your environment.

```
. ./x86_64-anywhere-linux-gnu/scripts/anywhere-setup.sh
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

Source the `./scripts/anywhere-setup-security.sh` script adds extra linker and compiler flags.

```
. ./x86_64-anywhere-linux-gnu/scripts/anywhere-setup-security.sh
```

## Accuracy

This is a best-effort solution that covers most bases. Every project's build system is different and may not respect the variable this toolchain sets. Most problems can be resolved by telling autotools, cmake, etc, system about the explicit linking and include paths.

As an example, SleuthKit will still find the system `libstdc++.so` and OpenSSL needs an explicit `--prefix=$PREFIX`.

A more-accurate version forces the use of clang, clang's compiler runtime, and LLVM's `libc++`. This is more accurate because it is harder for build systems to work if they make assumptions (e.g., we did not read their documentation closely). So you either break it or it works, which is better. The side effect of this is about 100kB additional code from static linking compared to gcc's runtime and c++ implementation.

Add to `LDFLAGS`

```
-fuse-ld=lld -rtlib=compiler-rt -l:libc++.a -l:libc++abi.a -l:libunwind.a -lpthread -ldl
```

Add to `CXXFLAGS`

```
-stdlib=libc++
```

You can also remove the libc dynamic libraries to force anything trying to link them statically.
- `$PREFIX/lib/libc++*.so*`
- `$PREFIX/lib/libunwind*.so*`

Now build systems have no choice.


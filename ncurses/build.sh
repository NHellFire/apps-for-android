#!/bin/bash
set -eu

ANDROID_API=23
ARCH=arm64
NDK_ROOT=${NDK_ROOT:-/opt/android-ndk}


TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

[ -e "$TOP/../config.sh" ] && . "$TOP/../config.sh"

EABI=
case "$ARCH" in
	arm64)
		GCC_ARCH="aarch64"
	;;
	arm)
		GCC_ARCH="arm"
		EABI=eabi
	;;
	mips|mips64)
		GCC_ARCH="${ARCH}el"
	;;
	x86|x86_64)
		GCC_ARCH="${ARCH}"
	;;
	*)
		echo "Unknown architecture: ${ARCH}"
		exit
esac

export HOST="${GCC_ARCH}-linux-android$EABI"

TOOLCHAIN="${NDK_ROOT}/toolchains/${HOST}-4.9/prebuilt/linux-x86_64"

export CROSS_COMPILE="${HOST}-"

export PATH="$TOOLCHAIN/bin:$PATH"

export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT}"
export CPPFLAGS="-P"

PREFIX="/data/local/ncurses"

export DESTDIR="$TOP/install_dir/$ARCH/"

# Cleanup old output
rm -rf "$DESTDIR"
mkdir -p install_dir/$ARCH

cd src

cp "$TOP/patches/config.sub" "$TOP/patches/config.guess" -t .

# Need to build both without UTF-8 support
./configure --host=${HOST} \
		--prefix=${PREFIX} \
		--exec-prefix=${PREFIX} \
		--without-cxx \
		--without-cxx-binding \
		--without-debug \
		--without-normal \
		--without-progs \
		--with-terminfo-dirs=${PREFIX}/etc/terminfo \
		--with-default-terminfo-dir=${PREFIX}/etc/terminfo \
		--without-manpages \
		--with-shared \
		--with-termlib \
		--without-ada

make -j8

make install

# And with UTF-8 support
./configure --host=${HOST} \
		--prefix=${PREFIX} \
		--exec-prefix=${PREFIX} \
		--without-cxx \
		--without-cxx-binding \
		--without-debug \
		--without-normal \
		--without-progs \
		--with-terminfo-dirs=${PREFIX}/etc/terminfo \
		--with-default-terminfo-dir=${PREFIX}/etc/terminfo \
		--without-manpages \
		--with-shared \
		--enable-widec \
		--with-termlib \
		--without-ada

make -j8

make install

rm -rf "$DESTDIR/$PREFIX/bin" "$DESTDIR/$PREFIX/share"

printf "\n\nBuild complete! See install_dir/$ARCH/\n"

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

NCURSES_INSTALL="$TOP/../ncurses/install_dir/$ARCH/data/local/ncurses"
NCURSES_INCLUDE="$NCURSES_INSTALL/include"
NCURSES_LIB="$NCURSES_INSTALL/lib"

export CROSS_COMPILE="${HOST}-"
export PATH="$TOOLCHAIN/bin:$PATH"
export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT} -I$NCURSES_INCLUDE -L$NCURSES_LIB -fPIE"
export LDFLAGS="-L$NCURSES_LIB -pie"
export QUILT_PATCHES="$TOP/patches"

[ -e "$NCURSES_INCLUDE/ncursesw/ncurses.h" ] || env -i "$TOP/../ncurses/build.sh"

PREFIX="/data/local/htop"

export DESTDIR="$TOP/install_dir/$ARCH/"

# Cleanup old output
rm -rf "$DESTDIR"
mkdir -p "$DESTDIR"

cd src

quilt push -a

./autogen.sh

./configure --host=${HOST} \
		--prefix=${PREFIX} \
		--exec-prefix=${PREFIX} \
		--enable-unicode \
		--enable-shared=yes \
		--enable-static=no
make -j8

make install-strip
rm -rf "$DESTDIR/$PREFIX/share"

quilt pop -af

printf "\n\nBuild complete! See install_dir/$ARCH/\n"

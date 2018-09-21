#!/bin/bash
set -eu

ANDROID_API=23
ARCH=arm64
NDK_ROOT="${NDK_ROOT:-/opt/android-ndk}"

export PROJECT=nano

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

NCURSES_INSTALL="$OUTDIR/../ncurses/$ARCH/$PREFIX"
NCURSES_INCLUDE="$NCURSES_INSTALL/include"
NCURSES_LIB="$NCURSES_INSTALL/lib"

export CROSS_COMPILE="${HOST}-"
export PATH="$TOOLCHAIN/bin:$PATH"
export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT} -I$NCURSES_INCLUDE -L$NCURSES_LIB -I${NDK_ROOT}/sysroot/usr/include -fPIE"
export LDFLAGS="-L$NCURSES_LIB -pie"

[ -e "$NCURSES_INCLUDE/ncursesw/ncurses.h" ] || env -i "$TOP/../ncurses/build.sh"

export QUILT_PATCHES="$TOP/patches"
export DESTDIR="$TOP/install_dir/$ARCH/"

# Cleanup old output
rm -rf "${DESTDIR:?}"
mkdir -p "$DESTDIR"

cd src

gnulib-tool --import glob unistr/u8-mblen

quilt push -a ||  [ "$?" == "2" ]

./autogen.sh

./configure --host="${HOST}" \
		--prefix="${PREFIX}" \
		--exec-prefix="${PREFIX}" \
		--bindir="${PREFIX}/$BINDIR" \
		--sbindir="${PREFIX}/$BINDIR" \
		--enable-utf8 \
		ac_cv_func_nl_langinfo=yes ac_cv_func_mblen=yes

make -j1

make install-strip

printf "\n\nBuild complete! See OUTDIR/%s/\n" "$ARCH"

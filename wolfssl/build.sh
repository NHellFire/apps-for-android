#!/bin/bash
set -eu

ANDROID_API=23
ARCH=arm64
NDK_ROOT="${NDK_ROOT:-/opt/android-ndk}"

TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

export PROJECT=busybox
echo
echo "=============================="
echo "Building $PROJECT"

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

echo "Building for $ARCH"

export HOST="${GCC_ARCH}-linux-android$EABI"

TOOLCHAIN="${NDK_ROOT}/toolchains/${HOST}-4.9/prebuilt/linux-x86_64"

export CC="${HOST}-gcc"
export AR="${HOST}-ar"
export STRIP="${HOST}-strip"

export PATH="$TOOLCHAIN/bin:$PATH"

export CFLAGS="--sysroot=${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH} -fpie -DWOLFSSL_STATIC_RSA"
export LDFLAGS="-pie"

cd "${TOP}/src"

./autogen.sh

./configure \
	--host="$HOST" \
	--enable-static \
	--disable-shared \
	--enable-singlethreaded \
	--with-libz

make -j"$(nproc)"

printf "\n\nBuild complete!\n"

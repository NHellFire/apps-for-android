#!/bin/bash
set -e

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




export CC="${HOST}-gcc"
export STRIP="${HOST}-strip"

export PATH="$TOOLCHAIN/bin:$PATH"

export CFLAGS="--sysroot=${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH} -fpie"
export LDFLAGS="-pie"

export CC="$CC $CFLAGS $LDFLAGS"

cd "${TOP}/src"

make clean
make -j$(nproc)

cd "${TOP}"

rm -rf install_dir/$ARCH/
mkdir -p install_dir/$ARCH/
cp -v src/fdupes install_dir/$ARCH/
${STRIP} install_dir/$ARCH/fdupes


printf "\n\nBuild complete! See install_dir/$ARCH\n"

#!/bin/bash
set -e

ANDROID_API=23
ARCH=arm64
NDK_ROOT=${NDK_ROOT:-/opt/android-ndk}


TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

[ -e "$TOP/../config.sh" ] && . "$TOP/../config.sh"

if [ "$ARCH" = "arm64" ]; then
	printf "Stable OpenSSL currently doesn't support ARM64 Android builds, forcing ARM\n"
	ARCH=arm
fi


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


# OpenSSL specific stuff
export MACHINE=armv7l
export SYSTEM=android
export ARCH=arm
export ANDROID_DEV=$SYSROOT/usr

cd src


# Android 4.1+ requires PIE
perl -pi -e 's/"android-armv7","gcc:/"android-armv7","gcc:-fpie -pie /g' Configure

./config no-shared no-ssl2 no-ssl3 no-comp no-hw no-engine

make depend -j8

make -j8

${CROSS_COMPILE}strip apps/openssl

# Cleanup old output
cd "$TOP"
rm -rf install_dir/
mkdir -p install_dir


cp -v src/apps/openssl install_dir/


printf "\n\nBuild complete! See install_dir/\n"

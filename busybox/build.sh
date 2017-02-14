#!/bin/bash
set -e

ANDROID_API=23
ARCH=arm64
NDK_ROOT=${NDK_ROOT:-/opt/android-ndk}


TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

WOLFSSL="$TOP/../wolfssl"

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

PATH="$TOOLCHAIN/bin:$PATH"

export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT}"

cd src

quilt push -a || [ $? = 2 ]

cp "patches/android_ndk_${ARCH}_defconfig" .config
yes '' | make oldconfig

make -j$(nproc)

quilt pop -af

# Cleanup old output
cd "$TOP"
rm -rf install_dir/$ARCH
mkdir -p install_dir/$ARCH


printf "\n\nNow building ssl_helper... "
"$WOLFSSL/build.sh"
${HOST}-gcc $CFLAGS -fpie -pie -I"$WOLFSSL/src" "src/networking/ssl_helper-wolfssl/ssl_helper.c" "$WOLFSSL/src/src/.libs/libwolfssl.a" -lm -lz -o install_dir/$ARCH/ssl_helper
${HOST}-strip install_dir/$ARCH/ssl_helper
printf "done\n"


cp -v src/busybox install_dir/$ARCH/
cp -v "${OPENSSL}/install_dir/$ARCH/openssl" install_dir/$ARCH/


printf "\n\nBuild complete! See install_dir/$ARCH/\n"

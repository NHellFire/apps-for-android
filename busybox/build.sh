#!/bin/bash
set -eu

ANDROID_API=23
ARCH=arm64
NDK_ROOT="${NDK_ROOT:-/opt/android-ndk}"

export PROJECT=busybox
echo
echo "=============================="
echo "Building $PROJECT"

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

echo "Building for $ARCH"

export HOST="${GCC_ARCH}-linux-android$EABI"

TOOLCHAIN="${NDK_ROOT}/toolchains/${HOST}-4.9/prebuilt/linux-x86_64"

export CROSS_COMPILE="${HOST}-"

export PATH="$TOOLCHAIN/bin:$PATH"

export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT}"

cd src

quilt push -a || [ $? = 2 ]

cp "patches/android_ndk_${ARCH}_defconfig" .config
yes '' | make oldconfig

make -j"$(nproc)"

quilt pop -af

# Cleanup old output
cd "$TOP"
rm -rf "${OUTDIR:?}/$ARCH"
mkdir -p "$OUTDIR/$ARCH/$PREFIX/$BINDIR"

cp -v src/busybox "$OUTDIR/$ARCH/$PREFIX/$BINDIR"

printf "\n\nBuild complete! See OUTDIR/%s/%s/\n" "$PROJECT" "$ARCH"

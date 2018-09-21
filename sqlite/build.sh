#!/bin/bash
set -eu

TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

export PROJECT=sqlite
echo
echo "=============================="
echo "Building $PROJECT"

[ -e "$TOP/../config.sh" ] && . "$TOP/../config.sh"

ANDROID_API="${ANDROID_API:-23}"
ARCH="${ARCH:-arm64}"
NDK_ROOT="${NDK_ROOT:-/opt/android-ndk}"

URL="https://sqlite.org/2018/sqlite-autoconf-3250100.tar.gz"
SHA1="1d494ca2355ffe8ddbeea7cf615ef61122fe421e"
NAME="${URL##*/}"

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

export PATH="$TOOLCHAIN/bin:$PATH"

export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT} -fPIE"
export LDFLAGS="-pie"

# Cleanup old output
cd "$TOP"
rm -rf "${OUTDIR:?}/$ARCH" src

# Download and extract source
wget --no-if-modified-since -N "$URL"
if ! echo "$SHA1 *$NAME" | sha1sum --status -c -; then
	echo "Hash on source didn't match"
	exit 1
fi

mkdir src
tar -C src --strip-components=1 -xf "$NAME"

cd src

#autoreconf -f -i

./configure --host="$HOST" \
	--prefix="${PREFIX}" \
	--exec-prefix="${PREFIX}" \
	--bindir="${PREFIX}/$BINDIR" \
	--sbindir="${PREFIX}/$BINDIR"

make -j"$BUILD_JOBS"

make install-strip DESTDIR="$OUTDIR/$ARCH"

printf "\n\nBuild complete! See OUTDIR/%s\n" "$ARCH"

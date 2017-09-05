#!/bin/bash
set -e

TOP="$(realpath "$(dirname "$0")")"
cd "${TOP}"

[ -z "$ARCH" ] && [ -e "$TOP/../config.sh" ] && . "$TOP/../config.sh"

ANDROID_API=${ANDROID_API:-23}
ARCH=${ARCH:-arm64}
NDK_ROOT=${NDK_ROOT:-/opt/android-ndk}

URL="https://sqlite.org/2017/sqlite-autoconf-3200100.tar.gz"
SHA1="48593dcd19473f25fe6fcd08048e13ddbff4c983"
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

export HOST="${GCC_ARCH}-linux-android$EABI"

TOOLCHAIN="${NDK_ROOT}/toolchains/${HOST}-4.9/prebuilt/linux-x86_64"

PATH="$TOOLCHAIN/bin:$PATH"

export SYSROOT="${NDK_ROOT}/platforms/android-${ANDROID_API}/arch-${ARCH}"
export CFLAGS="--sysroot=${SYSROOT} -fPIE"
export LDFLAGS="-pie"


# Cleanup old output
cd "$TOP"
rm -rf install_dir/$ARCH src

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

./configure --host=$HOST \
	--prefix=/data/local/sqlite \
	--sysconfdir=/data/local/sqlite \
	--bindir=/data/local/sqlite \
	--sbindir=/data/local/sqlite \
	--localstatedir=/data/local/sqlite

make -j8

make install-strip DESTDIR="$TOP/install_dir/$ARCH"

printf "\n\nBuild complete! See install_dir/\n"

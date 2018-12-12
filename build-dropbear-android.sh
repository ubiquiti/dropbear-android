#!/bin/bash

export CWD=$(pwd)

set -e

if [ -z ${TOOLCHAIN} ]; then
    echo "Setting TOOLCHAIN, you may set TOOLCHAIN manually by using:"
    echo "export TOOLCHAIN=/path/to/tc"
fi

# Setup the environment
export TARGET=../target
# Specify binaries to build. Options: dropbear dropbearkey scp dbclient
export PROGRAMS="dropbear dropbearkey dbclient dropbearconvert scp"
# Which version of Dropbear to download for patching
export VERSION=2018.76

if [ -z ${TOOLCHAIN} ]; then
    export TOOLCHAIN=$CWD/android-r11c-standalone-toolchain
fi
# Download the latest version of dropbear SSH
if [ ${TOOLCHAIN} = $CWD/android-r11c-standalone-toolchain ] && [ ! -d $CWD/android-r11c-standalone-toolchain ]; then
    echo ""
    echo "Fetching r11c standalone toolchain..."
    git clone https://github.com/Geofferey/android-r11c-standalone-toolchain.git
fi

echo ""

# Start each build with a fresh source copy
#rm -rf ./dropbear-$VERSION
#tar xjf dropbear-$VERSION.tar.bz2

# Change to dropbear directory
cd dropbear-$VERSION

### START -- configure without modifications first to generate files
#########################################################################################################################
echo "Generating required files..."

HOST=arm-linux-androideabi
COMPILER=${TOOLCHAIN}/bin/arm-linux-androideabi-gcc
STRIP=${TOOLCHAIN}/bin/arm-linux-androideabi-strip
SYSROOT=${TOOLCHAIN}/sysroot

export CC="$COMPILER --sysroot=$SYSROOT"

# Android 5.0 Lollipop and greater require PIE. Default to this unless otherwise specified.
if [ -z $DISABLE_PIE ]; then export CFLAGS="-g -O2 -pie -fPIE"; else echo "Disabling PIE compilation..."; fi
sleep 5
# Use the default platform target for pie binaries
unset GOOGLE_PLATFORM

# Apply the new config.guess and config.sub now so they're not patched
#cp ../config.guess ../config.sub .

make clean

./configure --host=$HOST --disable-zlib --disable-largefile --disable-shadow --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-pututxline --disable-lastlog > /dev/null 2>&1

echo "Done generating files"
sleep 2
echo
echo
#########################################################################################################################
### END -- configure without modifications first to generate files

# Begin applying changes to make Android compatible
# Apply the compatibility patch
#patch -p1 < ../android-compat.patch
#patch -p1 < ../dropbear-getpass-2018.patch
#patch -p1 < ../openpty.patch
cd -

echo "Compiling for ARM"

cd dropbear-$VERSION

make clean

./configure --host=$HOST --disable-zlib --disable-largefile --disable-shadow --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-pututxline --disable-lastlog

echo ""

read -p "Press Enter to Continue"

make PROGRAMS="$PROGRAMS"

MAKE_SUCCESS=$?
if [ $MAKE_SUCCESS -eq 0 ]; then
	clear
	sleep 1
  	# Create the output directory
	mkdir -p $TARGET/arm;
	for PROGRAM in $PROGRAMS; do

		if [ ! -f $PROGRAM ]; then
    		echo "${PROGRAM} not found!"
		fi

		$STRIP "./${PROGRAM}"
	done

	cp $PROGRAMS $TARGET/arm
	echo "Compilation successful. Output files are located in: ${TARGET}/arm"
else
 	echo "Compilation failed."
fi


#!/bin/bash

export CWD=$(pwd)

set -e

if [ -z ${TOOLCHAIN} ]; then
    echo ""
    echo "Setting TOOLCHAIN, you may set TOOLCHAIN manually by using:"
    echo "export TOOLCHAIN=/path/to/tc"
    echo ""
fi

if [ -z ${STATIC} ]; then
   export STATIC=1
fi

if [ -z ${MULTI} ]; then
    export MULTI=1

elif [ ${MULTI} = 1 ]; then
    export MULTI=0
fi

if [ $(echo "$PROGRAMS" | wc -w) = 1 ]; then
   export MULTI=0
fi

if [ -z ${INTERACTIVE} ]; then
    export INTERACTIVE=1
fi

# Setup the environment
export TARGET=../target

# Specify binaries to build. Options: dropbear dropbearkey scp dbclient
if [ -z ${PROGRAMS} ]; then
    export PROGRAMS="dropbear dropbearkey dbclient dropbearconvert scp"
fi

# Which version of Dropbear to download for patching
if [ -z ${VERSION} ]; then
    export VERSION=2018.76
fi

# Set the clean variable if not set and src is non existent
if [ -z ${CLEAN} ] && [ ! -d ${CWD}/dropbear-${VERSION} ]; then
    export CLEAN=1

elif [ -z ${CLEAN} ] && [ -d ${CWD}/dropbear-${VERSION} ]; then
    export CLEAN=0

fi

if [ ${CLEAN} = 0 ] && [ -z ${MAKE_CLEAN} ]; then
    export MAKE_CLEAN=1
else
    export MAKE_CLEAN=0
fi

#Download the dropbear source if not found
if [ ! -f ./dropbear-$VERSION.tar.bz2 ]; then
    wget -O ./dropbear-$VERSION.tar.bz2 https://matt.ucc.asn.au/dropbear/releases/dropbear-$VERSION.tar.bz2
fi

# Set default toolchain if none specified
if [ -z ${TOOLCHAIN} ]; then
    export TOOLCHAIN=$CWD/android-r11c-standalone-toolchain
fi

# Download the r11c standalone arm toolchain
if [ ${TOOLCHAIN} = $CWD/android-r11c-standalone-toolchain ] && [ ! -d $CWD/android-r11c-standalone-toolchain ]; then
    echo ""
    echo "Fetching r11c standalone toolchain..."
    git clone https://github.com/Geofferey/android-r11c-standalone-toolchain.git
fi

# Start each build with a fresh source copy it $CLEAN=1
if [ ${CLEAN} = 1 ]; then
    rm -rf ./dropbear-$VERSION
    tar xjf dropbear-$VERSION.tar.bz2
fi

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
if [ -z $DISABLE_PIE ]; then
    export CFLAGS="-g -O2 -pie -fPIE"
else
    echo "Disabling PIE compilation..."
fi

sleep 5

# Use the default platform target for pie binaries
unset GOOGLE_PLATFORM

if [ ${MAKE_CLEAN} = 1 ]; then
    make clean > /dev/null 2>&1
fi

./configure --host=$HOST --disable-zlib --disable-shadow --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-pututxline --disable-lastlog > /dev/null 2>&1

echo "Done generating files"

sleep 2

echo ""
#########################################################################################################################
### END -- configure without modifications first to generate files

# Begin applying changes to make Android compatible

# Apply the compatibility patch
sleep 10
if [ ${CLEAN} = 1 ]; then
    echo "Applying Android compatibility patch"

    patch -p1 < ../dropbear-$VERSION-android.patch

    sleep 3
fi

echo ""

cd -

echo "Compiling for ARM"

cd dropbear-$VERSION

if [ ${MAKE_CLEAN} = 1 ]; then
    make clean
fi

./configure --host=$HOST --disable-zlib --disable-largefile --disable-shadow --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-pututxline --disable-lastlog

echo "configure:"
echo "configure: Disregard warnings about crypt() & getpass()"

echo ""

echo "Nows your chance!"
echo "Make any changes to source then"

echo ""

if [ ! -z ${DEFAULT_PORT} ] && [ ${DEFAULT_PORT} -eq ${DEFAULT_PORT} ] > /dev/null 2>&1; then
    sed -i -e's/^#define DROPBEAR_DEFPORT .*/#define DROPBEAR_DEFPORT "'$DEFAULT_PORT'"/' ${CWD}/dropbear-${VERSION}/default_options.h
fi

if [ ! -z ${LOGIN_DIR} ]; then
    sed -i 's:^.*ses.authstate.pw_dir = m_strdup(".*");:                                ses.authstate.pw_dir = m_strdup("'"$LOGIN_DIR"'");:' ${CWD}/dropbear-$VERSION/svr-auth.c
fi

if [ ! -z ${HOSTKEYS_DIR} ]; then
    HOSTKEYS_DIR=$(echo "$HOSTKEYS_DIR" | sed 's:/*$::')
    sed -i 's:^#define DSS_PRIV_FILENAME ".*":#define DSS_PRIV_FILENAME "'$HOSTKEYS_DIR'/dropbear_dss_host_key":' ${CWD}/dropbear-${VERSION}/default_options.h
    sed -i 's:^#define RSA_PRIV_FILENAME ".*":#define RSA_PRIV_FILENAME "'$HOSTKEYS_DIR'/dropbear_rsa_host_key":' ${CWD}/dropbear-${VERSION}/default_options.h
    sed -i 's:^#define ECDSA_PRIV_FILENAME ".*":#define ECDSA_PRIV_FILENAME "'$HOSTKEYS_DIR'/dropbear_rsa_host_key":' ${CWD}/dropbear-${VERSION}/default_options.h
fi

if [ ! -z ${SFTPSERVER_PATH} ]; then
    SFTPSERVER_PATH=$(echo "$SFTPSERVER_PATH" | sed 's:/*$::')
    sed -i 's:^#define SFTPSERVER_PATH ".*":#define SFTPSERVER_PATH "'$SFTPSERVER_PATH'":' ${CWD}/dropbear-${VERSION}/default_options.h
fi

if [ ! -z ${PID_PATH} ]; then
    PID_PATH=$(echo "$PID_PATH" | sed 's:/*$::')
    sed -i 's:^#define DROPBEAR_PIDFILE ".*":#define DROPBEAR_PIDFILE "'$PID_PATH'":' ${CWD}/dropbear-${VERSION}/default_options.h
fi

if [ ! -z ${SSHCLI_PATH} ]; then
    SSHCLI_PATH=$(echo "$SSHCLI_PATH" | sed 's:/*$::')
    sed -i 's:^#define DROPBEAR_PATH_SSH_PROGRAM ".*":#define DROPBEAR_PATH_SSH_PROGRAM "'$SSHCLI_PATH'":' ${CWD}/dropbear-${VERSION}/default_options.h 
fi

if [ ! -z ${DEFAULT_PATH} ]; then
    DEFAULT_PATH=$(echo "$DEFAULT_PATH" | sed 's:/*$::')
    sed -i 's,^#define DEFAULT_PATH ".*",#define DEFAULT_PATH "'$DEFAULT_PATH'",' ${CWD}/dropbear-${VERSION}/default_options.h
fi

if [ ${INTERACTIVE} = 1 ]; then
    read -p "Press Return to Continue..."
fi

STATIC="$STATIC" MULTI="$MULTI" SCPPROGRESS=0 PROGRAMS="$PROGRAMS" make

if [ ${MULTI} = 1 ]; then
    BUILT_PROGS="$PROGRAMS"
    PROGRAMS="dropbearmulti"
fi

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

touch $TARGET/arm/build.info

echo  "# Build Completed:" "$(date)" > $TARGET/arm/build.info
echo "CLEAN=""$CLEAN" >> $TARGET/arm/build.info
echo "DEFAULT_PATH=""$DEFAULT_PATH" >> $TARGET/arm/build.info
echo "DEFAULT_PORT=""$DEFAULT_PORT" >> $TARGET/arm/build.info
echo "DISABLE_PIE""$DISABLE_PIE" >> $TARGET/arm/build.info
echo "HOSTKEYS_DIR=""$HOSTKEYS_DIR" >> $TARGET/arm/build.info
echo "INTERACTIVE=""$INTERACTIVE" >> $TARGET/arm/build.info
echo "LOGIN_DIR=""$LOGIN_DIR" >> $TARGET/arm/build.info
echo "MAKE_CLEAN=""$MAKE_CLEAN" >> $TARGET/arm/build.info

if [ ${MULTI} = 1 ]; then
    export MULTI=0
    echo "MULTI=""$MULTI" >> $TARGET/arm/build.info
        elif [ ${MULTI} = 0 ]; then
            export MULTI=1
            echo "MULTI=""$MULTI" >> $TARGET/arm/build.info
fi

echo "PID_PATH=""$PID_PATH" >> $TARGET/arm/build.info
echo "PROGRAMS=""$BUILT_PROGS" >> $TARGET/arm/build.info
echo "SFTPSERVER_PATH=""$SFTPSERVER_PATH" >> $TARGET/arm/build.info
echo "STATIC=""$STATIC" >> $TARGET/arm/build.info
echo "TOOLCHAIN=""$TOOLCHAIN" >> $TARGET/arm/build.info
echo "VERSION=""$VERSION" >> $TARGET/arm/build.info

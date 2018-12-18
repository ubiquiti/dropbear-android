Android Dropbear 2018.76
=========

A script & patch to cross-compile Dropbear SSH server/client for use on Android with password authentication.
Since the 64-bit binaries don't seem to work reliably, this project is configured to compile a single muti-purpose 32-bit binary
using a standalone Android ```r11c``` NDK toolchain.

Generated binary will be PIE (position indepedent executable) as required on Android 5 (L/ollipop) and above.

If building for android < 4.1 then before building, issue:
```
export DISABLE_PIE=1
```

Building Dropbear for Android
----

The process consists of just 3 parts:  

1) Git clone this repo:   
```
git clone https://github.com/Geofferey/dropbear-android.git
```  

2) Change to the direcotry:  
```
cd android-dropbear
```

3) Run the build script:  
```
./build.sh
```

Generated binary will be outputted to ``{android dropbear repo directory}/target/arm/dropbearmulti``


Customizations
----

Much of the project is pre-configured with sane defaults, but if you'd like to customize the behavior of Dropbear for Android, here are a few tips.
1) To change/configure most options, look in and modify the following files as appropriate:  
	a) default_options.h  
	b) sysoptions.h  
	c) config.h  

For instance, to change the port Dropbear runs on or to change the default location in which Dropbear tries to generate keys, edit ``default_options.h`` and modify the respective values.  

2) It is also possible to change behavior of build script by exporting vars before execution.  
        a) to build different version ```export VERSION=```  
        b) to build multiple binaries ```export MULTI=1```  
        c) to build non static binaries ```export STATIC=0```  
        d) to select programs to output ```export PROGRAMS=```  
		available programs ```dbclient dropbear dropbearconvert dropbearkey scp```  
        e) to use another toolchain ```export TOOLCHAIN=/path/to/tc```  

Build Time VARs
----
Here is a list of variables to be exported before running the build in order to customize the outputted bin(s) and behavior of script. The values below are the defaults when unspecified.     

- Starts build from unpatched unmodified copy of source  
```CLEAN=0```  

- Defines the default listening port for the Dropbear server  
```DEFAULT_PORT=10022```  

- Define the PATH(s) to binary executables on Android  
```DEFAULT_PATH```  

- Disables build of PIE binary  
```DISABLE_PIE```  

- Specifies the directory dropbear stores and loads host keys from  
```HOSTKEYS_DIR=./```  

- Run the build in interactive mode to allow for modifications (Press Return to Continue...)  
```INTERACTIVE=1```  

- Default directory to start in upon successful login  
```LOGIN_DIR=/data/local```  

- Runs 'make clean' before compilation  
```MAKE_CLEAN=1```  

- Outputs multiple binaries instead of combined linkable binary  
```MULTI=0```  

- Path to store process ID  
```PID_PATH=```  

- Programs to build  
```PROGRAMS=dropbear dbclient dropbearconvert dropbearkey scp```  

- Path to sftp-server  
```SFTPSERVER_PATH=/usr/libexec/sftp-server```  

- Path to the ssh client  
```SSHCLI_PATH=/usr/bin/dbclient```  

- Build statically linked binary  
```STATIC=1```  

- Path to the toolchain  
```TOOLCHAIN=/dropbear-android/android-rc11-standalone-toolchain```  


Basic usage
----
Dropbear for Android adds a few special flags to Dropbear:  
- A: signifies Android mode and allows for password authentication in the absence of the ```crypt()``` lib
- G: allows us to specify the GID dropbear should run as  
- U: allows us to specify the UID dropbear should run as  
- N: specify the login username for the session  
- T: specify the authentication key for the session  

A typical usecase would be:  
```
./dropbear -d /path/to/dropbear_dss_host_key -r /path/to/dropbear_rsa_hostkey -p 10022 -P /path/to/dropbear.pid -R -A -N user -C password -U u0_aXX -G u0_aXX
```

The above command will run the Dropbear server with password authentication enabled for the user 'user' with password 'password' and will attempt to run as u0_aXX and in that group. More information can be found by issuing:  
  
```
./dropbear --help
````

Contributions
----
Big thanks to mkj who has been maintaining Dropbear:  
https://github.com/mkj/dropbear


Thanks to NHellfire who's work made the process of getting 2018.76 up and running much easier:  
https://github.com/NHellFire/dropbear-android  


Thanks to jmfoy for the ```config.sub``` and ```config.guess``` files:  
https://github.com/jfmoy/android-dropbear


Thanks to wolfdude & serasihay @XDA for ```netbsd_getpass.c``` implementation:  
https://forum.xda-developers.com/nexus-7-2013/general/guide-compiling-dropbear-2015-67-t3142412/page2  
https://forum.xda-developers.com/nexus-7-2013/general/guide-compiling-dropbear-2016-73-t3351671  


Thanks to yoshinrt for ```openpty.patch``` fix:  
https://github.com/yoshinrt/dropbear-android

Another thank you to the various repositories out there whose contributions helped lead to the completion of this project.

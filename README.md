Android Dropbear
=========

A patch set and script to cross-compile Dropbear SSH server for use on Android with password authentication.
As the 64-bit binaries don't seem to work reliably, this project is configured to compile 32-bit binaries
using the Android NDK toolchain.

Generated binares will all be PIE (position indepedent executable) binaries as it is required on Android 5 (L/ollipop).

If building for android < 4.1 then before building, issue:
```
export DISABLE_PIE=1
```

Building Dropbear for Android
----

The process consists of just three parts:
1) Build your standalone android toolchain.  
See the android developer site for more info: https://developer.android.com/ndk/guides/standalone_toolchain.html
2) Export your toolchain's location:
```
export TOOLCHAIN=/path/to/standalone/toolchain
```

3) Run the build script:
```
./build-dropbear-android.sh
```

Generated binaries will be outputted to ``{android dropbear repo directory}/target/arm``


Customizations
----

Much of the project is pre-configured with sane defaults, but if you'd like to customize the behavior of Dropbear for Android, here are a few tips.
1) To change/configure most options, look in and modify the following files as appropriate:  
	a) default_options.h  
	b) systoptions.h  
	c) config.h  

For instance, to change the port Dropbear runs on or to change the default location in which Dropbear tries to generate keys, edit ``default_options.h`` and modify the respective values.

Credits
----
Big thanks to mkj who has been maintaining Dropbear:  
https://github.com/mkj/dropbear  

Thanks to NHellfire who's work made the process of getting 2018.76 up and running much easier:  
https://github.com/NHellFire/dropbear-android  

Another thank you to the various other repositories out there whose various approches helped lead to this completed project.

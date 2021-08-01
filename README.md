# DragonRoot

A simple initramfs builder for DragonKexec, currently supporting:

- Xiaomi Pocophone F1 (Not Tested)
- OnePlus 6 (Not Tested)
- OnePlus 6T (Not Tested)
- Redmi 2 
- Motorola G4 Play
  

### Qualcomm Devices Usage

Boot the image using `fastboot boot`.

### Building

The dependencies are:

Additional dependencies for Qualcomm Devices:
- mkbootimg

```shell-session

$ make -j8 boot-xiaomi-beryllium-tianma.img
Builds everything needed for the pinephone image...

$ make -j8 all
Generates an image for every supported platform in parallel

$ fastboot boot boot-xiaomi-beryllium-tianma.img
Let DragonKexec Rock in Your Phone!

$ fastboot flash boot boot-xiaomi-beryllium-tianma.img
Install DragonKexec to your smart phone!

```

### This project is built on:
- [Busybox](https://busybox.net) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [postmarketOS](https://postmarketos.org) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [JumpDrive](https://github.com/dreemurrs-embedded/Jumpdrive) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).



CROSS_FLAGS = ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
CROSS_FLAGS_BOOT = CROSS_COMPILE=aarch64-linux-gnu-

all: boot-xiaomi-beryllium-tianma.img boot-xiaomi-beryllium-ebbg.img boot-oneplus-enchilada.img boot-oneplus-fajita.img boot-xiaomi-wt88047.img boot-motorola-harpia.img

kernel-xiaomi-beryllium-tianma.gz-dtb: kernel-sdm845.gz dtbs/sdm845/sdm845-xiaomi-beryllium-tianma.dtb
	cat kernel-sdm845.gz dtbs/sdm845/sdm845-xiaomi-beryllium-tianma.dtb > $@

kernel-xiaomi-beryllium-ebbg.gz-dtb: kernel-sdm845.gz dtbs/sdm845/sdm845-xiaomi-beryllium-ebbg.dtb
	cat kernel-sdm845.gz dtbs/sdm845/sdm845-xiaomi-beryllium-ebbg.dtb > $@

kernel-oneplus-enchilada.gz-dtb: kernel-sdm845.gz dtbs/sdm845/sdm845-oneplus-enchilada.dtb
	cat kernel-sdm845.gz dtbs/sdm845/sdm845-oneplus-enchilada.dtb > $@

kernel-oneplus-fajita.gz-dtb: kernel-sdm845.gz dtbs/sdm845/sdm845-oneplus-fajita.dtb
	cat kernel-sdm845.gz dtbs/sdm845/sdm845-oneplus-fajita.dtb > $@

kernel-xiaomi-wt88047.gz-dtb: kernel-msm8916.gz dtbs/msm8916/msm8916-wingtech-wt88047.dtb
	cat kernel-msm8916.gz dtbs/msm8916/msm8916-wingtech-wt88047.dtb > $@

kernel-motorola-harpia.gz-dtb: kernel-msm8916.gz dtbs/msm8916/msm8916-motorola-harpia.dtb
	cat kernel-msm8916.gz dtbs/msm8916/msm8916-motorola-harpia.dtb > $@

boot-%.img: initramfs-%.gz kernel-%.gz-dtb
	rm -f $@
	$(eval BASE := $(shell cat src/deviceinfo_$* | grep base | cut -d "\"" -f 2))
	$(eval SECOND := $(shell cat src/deviceinfo_$* | grep second | cut -d "\"" -f 2))
	$(eval KERNEL := $(shell cat src/deviceinfo_$* | grep kernel | cut -d "\"" -f 2))
	$(eval RAMDISK := $(shell cat src/deviceinfo_$* | grep ramdisk | cut -d "\"" -f 2))
	$(eval TAGS := $(shell cat src/deviceinfo_$* | grep tags | cut -d "\"" -f 2))
	$(eval PAGESIZE := $(shell cat src/deviceinfo_$* | grep pagesize | cut -d "\"" -f 2))
	mkbootimg --kernel kernel-$*.gz-dtb --ramdisk initramfs-$*.gz --base $(BASE) --second_offset $(SECOND) --kernel_offset $(KERNEL) --ramdisk_offset $(RAMDISK) --tags_offset $(TAGS) --pagesize $(PAGESIZE) --cmdline console=ttyMSM0,115200 -o $@

%.img.xz: %.img
	@echo "XZ    $@"
	@xz -c $< > $@

initramfs/bin/busybox: src/busybox src/busybox_config
	@echo "MAKE  $@"
	@mkdir -p build/busybox
	@cp src/busybox_config build/busybox/.config
	@$(MAKE) -C src/busybox O=../../build/busybox $(CROSS_FLAGS)
	@cp build/busybox/busybox initramfs/bin/busybox

initramfs/bin/bash: src/bash
	@echo "MAKE  $@"
	@mkdir -p build/bash
	@cd build/bash;\
	../../src/bash/configure --host=aarch64-linux-gnu --enable-static-link --without-bash-malloc
	@$(MAKE) -C build/bash
	@aarch64-linux-gnu-strip build/bash/bash
	@upx --best build/bash/bash
	@cp build/bash/bash initramfs/bin/bash

initramfs/bin/kexec: src/kexec-tools
	@echo "MAKE  $@"
	@mkdir -p build/kexec-tools
	@cd src/kexec-tools;./bootstrap
	@cd build/kexec-tools;\
	LDFLAGS=-static ../../src/kexec-tools/configure --host=aarch64-linux-gnu
	@$(MAKE) -C build/kexec-tools
	@aarch64-linux-gnu-strip build/kexec-tools/build/sbin/kexec
	@upx --best build/kexec-tools/build/sbin/kexec
	@cp build/kexec-tools/build/sbin/kexec initramfs/bin/kexec
	
initramfs-%.cpio: initramfs/bin/kexec initramfs/bin/bash initramfs/bin/busybox initramfs/init initramfs/init_functions.sh
	@echo "CPIO  $@"
	@rm -rf initramfs-$*
	@cp -r initramfs initramfs-$*
	@cp src/info-$*.sh initramfs-$*/info.sh
	@cp src/info-$*.sh initramfs-$*/info.sh
	@cd initramfs-$*; find . | cpio -H newc -o > ../$@
	
initramfs-%.gz: initramfs-%.cpio
	@echo "GZ    $@"
	@gzip < $< > $@
	
kernel-sdm845.gz: src/linux-sdm845
	@echo "MAKE  $@"
	@mkdir -p build/linux-sdm845
	@mkdir -p dtbs/sdm845
	@$(MAKE) -C src/linux-sdm845 O=../../build/linux-sdm845 $(CROSS_FLAGS) defconfig sdm845.config
	@printf "CONFIG_USB_ETH=n" >> build/linux-sdm845/.config
	@$(MAKE) -C src/linux-sdm845 O=../../build/linux-sdm845 $(CROSS_FLAGS) -j16
	@cp build/linux-sdm845/arch/arm64/boot/Image.gz $@
	@cp build/linux-sdm845/arch/arm64/boot/dts/qcom/sdm845-{xiaomi-beryllium-*,oneplus-enchilada,oneplus-fajita}.dtb dtbs/sdm845/

kernel-msm8916.gz: src/linux-msm8916
	@echo "MAKE  $@"
	@mkdir -p build/linux-msm8916
	@mkdir -p dtbs/msm8916
	@$(MAKE) -C src/linux-msm8916 O=../../build/linux-msm8916 $(CROSS_FLAGS) msm8916_defconfig
	@$(MAKE) -C src/linux-msm8916 O=../../build/linux-msm8916 $(CROSS_FLAGS) -j16
	@cp build/linux-msm8916/arch/arm64/boot/Image.gz $@
	@cp build/linux-msm8916/arch/arm64/boot/dts/qcom/msm8916-*.dtb dtbs/msm8916/


dtbs/sdm845/sdm845-xiaomi-beryllium-ebbg.dtb: kernel-sdm845.gz

dtbs/sdm845/sdm845-xiaomi-beryllium-tianma.dtb: kernel-sdm845.gz

dtbs/sdm845/sdm845-oneplus-enchilada.dtb: kernel-sdm845.gz

dtbs/sdm845/sdm845-oneplus-fajita.dtb: kernel-sdm845.gz

dtbs/msm8916/msm8916-wingtech-wt88047.dtb: kernel-msm8916.gz

dtbs/msm8916/msm8916-motorola-harpia.dtb: kernel-msm8916.gz

src/linux-sdm845:
	@echo "WGET linux-sdm845"
	@mkdir src/linux-sdm845
	@wget -c https://gitlab.com/sdm845-mainline/linux/-/archive/b7a1e57f78d690d02aff902114bf2f6ca978ecfe/linux-b7a1e57f78d690d02aff902114bf2f6ca978ecfe.tar.gz
	@tar -xf linux-b7a1e57f78d690d02aff902114bf2f6ca978ecfe.tar.gz --strip-components 1 -C src/linux-sdm845

src/linux-msm8916:
	@echo "Clone linux-msm8916"
	@git clone https://github.com/Project-DragonPi/linux-msm.git --depth=1 src/linux-msm8916	

src/busybox:
	@echo "WGET  busybox"
	@mkdir src/busybox
	@wget https://www.busybox.net/downloads/busybox-1.32.0.tar.bz2
	@tar -xf busybox-1.32.0.tar.bz2 --strip-components 1 -C src/busybox

src/bash:
	@echo "WGET  bash"
	@mkdir src/bash
	@wget http://git.savannah.gnu.org/cgit/bash.git/snapshot/bash-5.0.tar.gz
	@tar -xvf bash-5.0.tar.gz --strip-components 1 -C src/bash

src/kexec-tools:
	@echo "WGET  kexec-tools"
	@mkdir src/kexec-tools
	@wget https://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git/snapshot/kexec-tools-2.0.20.tar.gz
	@tar -xvf kexec-tools-2.0.20.tar.gz --strip-components 1 -C src/kexec-tools

src/kexecboot:
	@echo "Clone kexecboot"
	@git clone https://github.com/kexecboot/kexecboot.git --depth=1 src/kexecboot

.PHONY: clean cleanfast

cleanfast:
	@rm -rvf build
	@rm -rvf initramfs-*/
	@rm -vf *.img
	@rm -vf *.img.xz
	@rm -vf *.tar.xz
	@rm -vf *.apk
	@rm -vf *.bin
	@rm -vf *.cpio
	@rm -vf *.gz
	@rm -vf *.gz-dtb

clean: cleanfast
	@rm -vf kernel*.gz
	@rm -vf initramfs/bin/busybox
	@rm -vrf dtbs

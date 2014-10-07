KERNEL_OPTS = \
	CROSS_COMPILE=arm-linux-gnueabi- \
	CFLAGS="-march=armv5te -mtune=arm926ej-s" \
	-j8
MIRROR = http://mirrors.kernel.org/debian
DEBOOTSTRAP_OPTS = \
	--foreign \
	--arch armel \
	--include sudo,firmware-ralink,isc-dhcp-client,wpasupplicant,ifupdown \
	--components main,contrib,non-free \
	--variant minbase
SUITE = testing

all: uzImage.bin scriptcmd rootfs.tar.gz

uzImage.bin: zImage_w_dtb
	mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 -n linux-vtwm -d $< $@

zImage_w_dtb: config | kernel
	$(MAKE) -C kernel ARCH=arm KCONFIG_CONFIG=../$< $(KERNEL_OPTS) zImage dtbs
	cat kernel/arch/arm/boot/zImage kernel/arch/arm/boot/dts/wm8505-ref.dtb > $@

config: seed | kernel
	cp $< $@.tmp
	$(MAKE) -C kernel ARCH=arm KCONFIG_CONFIG=../$@.tmp olddefconfig
	rm -f $@.tmp.old
	mv $@.tmp $@

kernel:
	git clone -b kernel "$(shell git config remote.origin.url)" $@

scriptcmd: cmd
	mkimage -A arm -O linux -T script -C none -a 1 -e 0 -n "script image" -d $< $@

rootfs.tar.gz: export DEBOOTSTRAP_OPTS := $(DEBOOTSTRAP_OPTS)
rootfs.tar.gz: buildrootfs debs.tar init.template eatmydata.deb
	fakeroot ./$< $@ $(MIRROR) $(SUITE)

debs.tar:
	fakeroot debootstrap $(DEBOOTSTRAP_OPTS) --make-tarball $@ $(SUITE) tmp $(MIRROR)

eatmydata.deb:
	wget -O $@ $(MIRROR)/pool/main/libe/libeatmydata/eatmydata_26-2_armel.deb

.PHONY: all

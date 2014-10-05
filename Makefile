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

all: uzImage.bin scriptcmd debs.tar
	fakeroot $(MAKE) rootfs.tar.gz

uzImage.bin: zImage_w_dtb
	mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 -n linux-vtwm -d $< $@

zImage_w_dtb: expanded kernel
	$(MAKE) -C kernel ARCH=arm $(KERNEL_OPTS) zImage dtbs
	cat kernel/arch/arm/boot/zImage kernel/arch/arm/boot/dts/wm8505-ref.dtb > $@

expanded: seed kernel
	cp $< kernel/.config
	$(MAKE) -C kernel ARCH=arm olddefconfig
	cp kernel/.config $@

kernel:
	git clone -b kernel --depth 1 "$(shell git config remote.origin.url)" $@

scriptcmd: cmd
	mkimage -A arm -O linux -T script -C none -a 1 -e 0 -n "script image" -d $< $@

rootfs.tar.gz: rootfs
	tar -czf $@ -C $< .

rootfs: debs.tar init.template eatmydata.deb
	debootstrap --unpack-tarball "$(CURDIR)/$<" $(DEBOOTSTRAP_OPTS) $(SUITE) $@ $(MIRROR)
	rm -f $@/etc/resolv.conf
	rm -f $@/etc/hostname
	rm -f $@/sbin/init
	sed < init.template > $@/sbin/init -e s,__MIRROR__,$(MIRROR),g -e s,__SUITE__,$(SUITE),g
	dpkg-deb --fsys-tarfile eatmydata.deb | tar -x --strip-components=4 -C $@/debootstrap ./usr/lib/libeatmydata/libeatmydata.so

debs.tar:
	debootstrap $(DEBOOTSTRAP_OPTS) --make-tarball $@ $(SUITE) tmp $(MIRROR)

eatmydata.deb:
	wget -O $@ $(MIRROR)/pool/main/libe/libeatmydata/eatmydata_26-2_armel.deb

.PHONY: all

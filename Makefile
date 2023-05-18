# export CROSS_COMPILE=arm-linux-gnueabihf-
# export PATH=$PATH:/home/trswany/Xilinx/Vitis/2021.2/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin
# export VIVADO_SETTINGS=/home/trswany/Xilinx/Vivado/2021.2/settings64.sh

ifndef CROSS_COMPILE
$(error CROSS_COMPILE is undefined)
endif
ifndef PATH
$(error PATH is undefined)
endif
ifndef VIVADO_SETTINGS
$(error VIVADO_SETTINGS is undefined)
endif

GCC_PATH = $(shell which $(CROSS_COMPILE)gcc)
TOOLCHAIN = $(shell dirname $(GCC_PATH))
TOOLCHAIN_PATH = $(shell dirname $(TOOLCHAIN))

NCORES = $(shell grep -c ^processor /proc/cpuinfo)
VSUBDIRS = hdl buildroot linux u-boot-xlnx
VERSION=$(shell git describe --abbrev=4 --dirty --always --tags)
UBOOT_VERSION=$(shell echo -n "PlutoLink " && cd u-boot-xlnx && git describe --abbrev=0 --dirty --always --tags)
TARGET_DTS_FILES:= zynq-pluto-sdr.dtb zynq-pluto-sdr-revb.dtb zynq-pluto-sdr-revc.dtb
COMPLETE_NAME:=PlutoLink

TARGETS = build/plutolink.frm build/boot.frm

all: $(TARGETS)

.NOTPARALLEL: all

TARGET_DTS_FILES:=$(foreach dts,$(TARGET_DTS_FILES),build/$(dts))

build:
	mkdir -p $@

%: build/%
	cp $< $@

### u-boot ###

u-boot-xlnx/u-boot u-boot-xlnx/tools/mkimage:
	make -C u-boot-xlnx ARCH=arm zynq_pluto_defconfig
	make -C u-boot-xlnx ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) UBOOTVERSION="$(UBOOT_VERSION)"

.PHONY: u-boot-xlnx/u-boot

build/u-boot.elf: u-boot-xlnx/u-boot | build
	cp $< $@

build/uboot-env.txt: u-boot-xlnx/u-boot | build
	CROSS_COMPILE=$(CROSS_COMPILE) scripts/get_default_envs.sh > $@

build/uboot-env.bin: build/uboot-env.txt
	u-boot-xlnx/tools/mkenvimage -s 0x20000 -o $@ $<

### Linux ###

linux/arch/arm/boot/zImage:
	make -C linux ARCH=arm zynq_pluto_defconfig
	make -C linux -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zImage UIMAGE_LOADADDR=0x8000

.PHONY: linux/arch/arm/boot/zImage


build/zImage: linux/arch/arm/boot/zImage  | build
	cp $< $@

### Device Tree ###

linux/arch/arm/boot/dts/%.dtb: linux/arch/arm/boot/dts/%.dts  linux/arch/arm/boot/dts/zynq-pluto-sdr.dtsi
	DTC_FLAGS=-@ make -C linux -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(notdir $@)

build/%.dtb: linux/arch/arm/boot/dts/%.dtb | build
	dtc -q -@ -I dtb -O dts $< | sed 's/axi {/amba {/g' | dtc -q -@ -I dts -O dtb -o $@

### Buildroot ###

buildroot/output/images/rootfs.cpio.gz:
	@echo device-fw $(VERSION)> $(CURDIR)/buildroot/board/pluto/VERSIONS
	@$(foreach dir,$(VSUBDIRS),echo $(dir) $(shell cd $(dir) && git describe --abbrev=4 --dirty --always --tags) >> $(CURDIR)/buildroot/board/pluto/VERSIONS;)
	make -C buildroot ARCH=arm zynq_pluto_defconfig
	make -C buildroot legal-info
	touch buildroot/board/pluto/msd/LICENSE.html
	make -C buildroot TOOLCHAIN_EXTERNAL_INSTALL_DIR=$(TOOLCHAIN_PATH) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) BUSYBOX_CONFIG_FILE=$(CURDIR)/buildroot/board/pluto/busybox-1.25.0.config all

.PHONY: buildroot/output/images/rootfs.cpio.gz

build/rootfs.cpio.gz: buildroot/output/images/rootfs.cpio.gz | build
	cp $< $@

build/plutolink.itb: u-boot-xlnx/tools/mkimage build/zImage build/rootfs.cpio.gz $(TARGET_DTS_FILES) build/system_top.bit
	u-boot-xlnx/tools/mkimage -f scripts/plutolink.its $@

build/system_top.xsa:  | build
	bash -c "source $(VIVADO_SETTINGS) && make -C hdl/projects/pluto && cp hdl/projects/pluto/pluto.sdk/system_top.xsa $@"
	unzip -l $@ | grep -q ps7_init || cp hdl/projects/pluto/pluto.srcs/sources_1/bd/system/ip/system_sys_ps7_0/ps7_init* build/

build/sdk/fsbl/Release/fsbl.elf build/system_top.bit : build/system_top.xsa
	rm -Rf build/sdk
	bash -c "source $(VIVADO_SETTINGS) && xsct scripts/create_fsbl_project.tcl"

build/boot.bin: build/sdk/fsbl/Release/fsbl.elf build/u-boot.elf
	@echo img:{[bootloader] $^ } > build/boot.bif
	bash -c "source $(VIVADO_SETTINGS) && bootgen -image build/boot.bif -w -o $@"

### MSD update firmware file ###

build/plutolink.frm: build/plutolink.itb
	md5sum $< | cut -d ' ' -f 1 > $@.md5
	cat $< $@.md5 > $@

build/boot.frm: build/boot.bin build/uboot-env.bin scripts/target_mtd_info.key
	cat $^ | tee $@ | md5sum | cut -d ' ' -f1 | tee -a $@

clean:
	make -C u-boot-xlnx clean
	make -C linux clean
	make -C buildroot clean
	make -C hdl clean
	rm -f $(notdir $(wildcard build/*))
	rm -rf build/*


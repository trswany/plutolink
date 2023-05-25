# PlutoLink

PlutoLink is a simple RF transceiver implementation using the ADALM-PLUTO RF
Learning Module. The host-side interface is UART-compatible and two PlutoLink
setups can be used to form a simple link between MCUs.

The RF processing is done exclusively in the Zynq FPGA fabric and is designed
to be portable to other non-Zynq FPGAs. The Zynq ARM core is used exclusively
for radio management and debug support. TX and RX can occur theoretically
anywhere in the 325 MHz to 3.8 GHz range that is supported by the module, but
operation is expected to be done by licensed HAMs in one of the allowable bands
(probably >2GHz).

## Background
This is a proof-of-concept project that is intended to explore the use of the
AD9363 RF transceiver with FPGAs to build low-power and low-cost transceiver
modules for use in Cubesats. The Zynq will be replaced in actual cubesats with
a low-cost FPGA (probably a Spartan or equivalent) and a low-power
microcontroller (probably a simple Cortex-M0).

## Pluto module and the PlutoSDR firmware

The ADALM-PLUTO module is an Analog Devices
[product](https://www.analog.com/en/design-center/evaluation-hardware-and-software/evaluation-boards-kits/adalm-pluto.html)
and instructions are located in a
[wiki](https://wiki.analog.com/university/tools/pluto).

This GitHub project is an adaptation of the
[plutosdr-fw](https://github.com/analogdevicesinc/plutosdr-fw)
GitHub project and includes only the rules that are needed to build the
*.frm image files that get used during USB mass-storage flashing. If you need
to do a DFU update (if you've bricked your device), use the official DFU image
and then do a USB mass-storage upgrade to PlutoLink.

## Build

Prep:

```
sudo apt-get install git build-essential fakeroot libncurses5-dev libssl-dev ccache
sudo apt-get install dfu-util u-boot-tools device-tree-compiler mtools
sudo apt-get install bc cpio zip unzip rsync file wget xvfb flex bison
git submodule update --recursive
```

Actual build (assumes Xilinx is installed in `~/Xilinx/`)

```
export CROSS_COMPILE=arm-linux-gnueabihf-
export PATH=$PATH:~/Xilinx/Vitis/2021.2/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin
export VIVADO_SETTINGS=~/Xilinx/Vivado/2021.2/settings64.sh
make
```

## Flash

Use the mass-storage update procedure that can be found in the Pluto wiki:
https://wiki.analog.com/university/tools/pluto/users/firmware

* Mount the mass-storage device
* Copy the "boot.frm" and "pluto.frm" files from the build folder to the root
  of the mass-storage device
* Eject the mass-storage device but **DO NOT UNPLUG** the Pluto module
* Wait for update to finish and the Pluto module to update and reboot

If the flashing fails for any reason, use the DFU update procedure and the
*.dfu files in the official Pluto release. Once the recovery is complete,
perform the mass-storage procedure again with the desired firmware.

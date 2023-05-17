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
plutolink.frm image file that gets used during USB mass-storage flashing. If
you need to do a DFU update (if you've bricked your device), use the official
DFU image and then do a USB mass-storage upgrade to PlutoLink.

// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  inout   [14:0]  ddr_addr,
  inout   [ 2:0]  ddr_ba,
  inout           ddr_cas_n,
  inout           ddr_ck_n,
  inout           ddr_ck_p,
  inout           ddr_cke,
  inout           ddr_cs_n,
  inout   [ 1:0]  ddr_dm,
  inout   [15:0]  ddr_dq,
  inout   [ 1:0]  ddr_dqs_n,
  inout   [ 1:0]  ddr_dqs_p,
  inout           ddr_odt,
  inout           ddr_ras_n,
  inout           ddr_reset_n,
  inout           ddr_we_n,

  inout           fixed_io_ddr_vrn,
  inout           fixed_io_ddr_vrp,
  inout   [31:0]  fixed_io_mio,
  inout           fixed_io_ps_clk,
  inout           fixed_io_ps_porb,
  inout           fixed_io_ps_srstb,

  inout           iic_scl,
  inout           iic_sda,

  input           rx_clk_in,
  input           rx_frame_in,
  input   [11:0]  rx_data_in,
  output          tx_clk_out,
  output          tx_frame_out,
  output  [11:0]  tx_data_out,

  output          enable,
  output          txnrx,
  input           clk_out,

  inout           gpio_resetb,
  inout           gpio_en_agc,
  inout   [ 3:0]  gpio_ctl,
  inout   [ 7:0]  gpio_status,

  output          spi_csn,
  output          spi_clk,
  output          spi_mosi,
  input           spi_miso,

  input           pl_uart_rx,
  output          pl_uart_cts,
  output          pl_uart_tx
);

  // internal signals

  wire    [16:0]  gpio_i;
  wire    [16:0]  gpio_o;
  wire    [16:0]  gpio_t;

  wire    [7:0]   uart_tx_word, uart_rx_word;
  wire            uart_buffer_empty;
  wire            uart_tx_start;
  wire            uart_tx_ready;
  wire            uart_buffer_put;
  wire            uart_sample_trigger;
  wire            sys_cpu_clk;
  wire            sys_cpu_reset;

  // instantiations

  ad_iobuf #(
    .DATA_WIDTH(14)
  ) i_iobuf (
    .dio_t (gpio_t[13:0]),
    .dio_i (gpio_o[13:0]),
    .dio_o (gpio_i[13:0]),
    .dio_p ({ gpio_resetb,        // 13:13
              gpio_en_agc,        // 12:12
              gpio_ctl,           // 11: 8
              gpio_status}));     //  7: 0

  assign gpio_i[16:14] = gpio_o[16:14];

  ring_buffer #(
    .WordLengthBits(8),
    .NumWords(128)
  ) uart_ring_buffer(
    .clk(sys_cpu_clk),
    .rst(sys_cpu_reset),
    .put(uart_buffer_put),
    .get(uart_tx_ready),
    .data_in(uart_rx_word),
    .data_out(uart_tx_word),
    .data_out_valid(uart_tx_start),
    .buffer_empty(pl_uart_cts),
    .buffer_100p_full()
  );

  // Divide the 100MHz sys_cpu_clk by 54 to get 1.851MHz.
  // That's roughly 16x of a 115200 baud rate (0.5% error).
  pulse_generator #(.Period(54)) uart_pulse_generator(
    .clk(sys_cpu_clk),
    .rst(sys_cpu_reset),
    .pulse(uart_sample_trigger)
  );

  uart_rx uart_rx (
    .clk(sys_cpu_clk),
    .rst(sys_cpu_reset),
    .sample_trigger(uart_sample_trigger),
    .raw_data(pl_uart_rx),
    .data(uart_rx_word),
    .data_valid(uart_buffer_put)
  );

  uart_tx uart_tx (
    .clk(sys_cpu_clk),
    .rst(sys_cpu_reset),
    .sample_trigger(uart_sample_trigger),
    .data(uart_tx_word),
    .start(uart_tx_start),
    .serial_data(pl_uart_tx),
    .ready(uart_tx_ready)
  );

  ad936x_data_interface (
    .clk(sys_cpu_clk),
    .rst(sys_cpu_reset),
    .bbp_rx_data_i(),
    .bbp_rx_data_q(),
    .bbp_rx_data_ready(1'b1),
    .bbp_rx_data_valid(),
    .bbp_tx_data_i(12'b0),
    .bbp_tx_data_q(12'b0),
    .bbp_tx_data_ready(),
    .bbp_tx_data_valid(1'b1),
    .ad936x_rx_data(rx_data_in),
    .ad936x_rx_frame(rx_frame_in),
    .ad936x_data_clk(rx_clk_in),
    .ad936x_data_clk_fb(tx_clk_out),
    .ad936x_tx_data(tx_data_out),
    .ad936x_tx_frame(tx_frame_out)
  );

  // TODO: replace these with actual controls.
  assign enable = gpio_o[15];
  assign txnrx = gpio_o[16];

  system_wrapper i_system_wrapper (
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),

    .sys_cpu_clk (sys_cpu_clk),
    .sys_cpu_reset (sys_cpu_reset),

    .spi0_clk_i (1'b0),
    .spi0_clk_o (spi_clk),
    .spi0_csn_0_o (spi_csn),
    .spi0_csn_1_o (),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi_miso),
    .spi0_sdo_i (1'b0),
    .spi0_sdo_o (spi_mosi),

    .spi_clk_i(1'b0),
    .spi_clk_o(),
    .spi_csn_i(1'b1),
    .spi_csn_o(),
    .spi_sdi_i(1'b0),
    .spi_sdo_i(1'b0),
    .spi_sdo_o());

endmodule

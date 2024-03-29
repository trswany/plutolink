
####################################################################################
## Copyright (c) 2018 - 2021 Analog Devices, Inc.
### SPDX short identifier: BSD-1-Clause
####################################################################################

####################################################################################
## Modified by Tom Swanson <trswany@gmail.com>
####################################################################################

set rfkit_src_dir ../rfkit/src

source ../hdl/scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

adi_project_create plutolink 0 {} "xc7z010clg225-1"

adi_project_files plutolink [list \
  "system_top.v" \
  "system_constr.xdc" \
  "$ad_hdl_dir/library/common/ad_iobuf.v" \
  "$rfkit_src_dir/pulse_generator/pulse_generator.sv" \
  "$rfkit_src_dir/ring_buffer/ring_buffer.sv" \
  "$rfkit_src_dir/ad936x_data_interface/ad936x_data_interface.sv" \
  "$rfkit_src_dir/bram/bram_dual_port.sv" \
  "$rfkit_src_dir/fir/fir.sv" \
  "$rfkit_src_dir/frequency_locked_loop/frequency_locked_loop.sv" \
  "$rfkit_src_dir/uart/start_bit_detector.sv" \
  "$rfkit_src_dir/uart/bit_sampler.sv" \
  "$rfkit_src_dir/uart/uart_rx.sv" \
  "$rfkit_src_dir/uart/uart_tx.sv" \
  "$rfkit_src_dir/cic/integrator.sv" \
  "$rfkit_src_dir/cic/comb.sv" \
  "$rfkit_src_dir/cic/decimator.sv" \
  "$rfkit_src_dir/cic/compensator.sv" \
  "$rfkit_src_dir/cic/cic_decimator.sv"
]

set_property is_enabled false [get_files  *system_sys_ps7_0.xdc]
adi_project_run plutolink

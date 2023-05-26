
####################################################################################
## Copyright (c) 2018 - 2021 Analog Devices, Inc.
### SPDX short identifier: BSD-1-Clause
####################################################################################

####################################################################################
## Modified by Tom Swanson <trswany@gmail.com>
####################################################################################

source ../hdl/scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

adi_project_create plutolink 0 {} "xc7z010clg225-1"

adi_project_files plutolink [list \
  "system_top.v" \
  "system_constr.xdc" \
  "$ad_hdl_dir/library/common/ad_iobuf.v"]

set_property is_enabled false [get_files  *system_sys_ps7_0.xdc]
adi_project_run plutolink
source $ad_hdl_dir/library/axi_ad9361/axi_ad9361_delay.tcl

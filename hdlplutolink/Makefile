####################################################################################
## Copyright (c) 2018 - 2021 Analog Devices, Inc.
### SPDX short identifier: BSD-1-Clause
####################################################################################

####################################################################################
## Modified by Tom Swanson <trswany@gmail.com>
####################################################################################

PROJECT_NAME := plutolink

HDL_PROJECT_PATH := ../hdl/projects/
HDL_LIBRARY_PATH := ../hdl/library/
RFKIT_LIBRARY_PATH := ../rfkit/src/

M_DEPS += $(HDL_PROJECT_PATH)common/xilinx/adi_fir_filter_constr.xdc
M_DEPS += $(HDL_PROJECT_PATH)common/xilinx/adi_fir_filter_bd.tcl
M_DEPS += $(HDL_LIBRARY_PATH)util_cdc/sync_bits.v
M_DEPS += $(HDL_LIBRARY_PATH)common/util_pulse_gen.v
M_DEPS += $(HDL_LIBRARY_PATH)common/ad_iobuf.v
M_DEPS += $(HDL_LIBRARY_PATH)common/ad_bus_mux.v

M_DEPS += $(RFKIT_LIBRARY_PATH)demo_inverter/demo_inverter.sv

LIB_DEPS += axi_dmac
LIB_DEPS += util_pack/util_cpack2
LIB_DEPS += util_pack/util_upack2

include ../hdl/quiet.mk

VIVADO := vivado -mode batch -source

CLEAN_TARGET := *.cache
CLEAN_TARGET += *.data
CLEAN_TARGET += *.xpr
CLEAN_TARGET += *.log
CLEAN_TARGET += *.jou
CLEAN_TARGET +=  xgui
CLEAN_TARGET += *.runs
CLEAN_TARGET += *.srcs
CLEAN_TARGET += *.sdk
CLEAN_TARGET += *.hw
CLEAN_TARGET += *.sim
CLEAN_TARGET += .Xil
CLEAN_TARGET += *.ip_user_files
CLEAN_TARGET += *.str
CLEAN_TARGET += mem_init_sys.txt
CLEAN_TARGET += *.csv
CLEAN_TARGET += *.hbs
CLEAN_TARGET += *.gen
CLEAN_TARGET += *.xpe
CLEAN_TARGET += *.xsa

M_DEPS += system_project.tcl
M_DEPS += system_bd.tcl
M_DEPS += system_top.v
M_DEPS += system_constr.xdc
M_DEPS += $(HDL_PROJECT_PATH)scripts/adi_project_xilinx.tcl
M_DEPS += $(HDL_PROJECT_PATH)../scripts/adi_env.tcl
M_DEPS += $(HDL_PROJECT_PATH)scripts/adi_board.tcl

M_DEPS += $(foreach dep,$(LIB_DEPS),$(HDL_LIBRARY_PATH)$(dep)/component.xml)

.PHONY: all lib clean clean-all
all: lib $(PROJECT_NAME).sdk/system_top.xsa

clean:
	-rm -f reference.dcp
	$(call clean, \
		$(CLEAN_TARGET), \
		$(HL)$(PROJECT_NAME)$(NC) project)

clean-all: clean
	@for lib in $(LIB_DEPS); do \
		$(MAKE) -C $(HDL_LIBRARY_PATH)$${lib} clean; \
	done

MODE ?= "default"

$(PROJECT_NAME).sdk/system_top.xsa: $(M_DEPS)
	@if [ $(MODE) = incr ]; then \
		if [ -f */impl_1/system_top_routed.dcp ]; then \
			echo Found previous run result at `ls */impl_1/system_top_routed.dcp`; \
			cp -u */impl_1/system_top_routed.dcp ./reference.dcp ; \
		fi; \
		if [ -f ./reference.dcp ]; then \
			echo Using reference checkpoint for incremental compilation; \
		fi; \
	else \
		rm -f reference.dcp; \
	fi;
	-rm -rf $(CLEAN_TARGET)
	$(call build, \
		$(VIVADO) system_project.tcl, \
		$(PROJECT_NAME)_vivado.log, \
		$(HL)$(PROJECT_NAME)$(NC) project)

lib:
	@for lib in $(LIB_DEPS); do \
		if [ -n "${REQUIRED_VIVADO_VERSION}" ]; then \
			$(MAKE) -C $(HDL_LIBRARY_PATH)$${lib} xilinx REQUIRED_VIVADO_VERSION=${REQUIRED_VIVADO_VERSION} || exit $$?; \
		else \
			$(MAKE) -C $(HDL_LIBRARY_PATH)$${lib} xilinx || exit $$?; \
		fi; \
	done



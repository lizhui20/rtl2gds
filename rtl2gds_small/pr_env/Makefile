SHELL := /bin/bash

FC_TOOL ?= /opt/synopsys/fusioncompiler/W-2024.09-SP3/bin/fc_shell
DC_TOOL ?= /opt/synopsys/syn/W-2024.09-SP3/bin/dcnxt_shell
TCLSH_TOOL ?= /opt/synopsys/SynopsysInstaller_v5.8/install_bin/Linux64/bin/tclsh8.6
LM_TOOL ?= /opt/synopsys/syn/W-2024.09-SP3/icc2/bin/lm_shell
STARRC_TOOL ?= /opt/synopsys/starrc/U-2022.12-SP5-2/bin/StarXtract
GRDGEN_TOOL ?= /opt/synopsys/starrc/U-2022.12-SP5-2/linux64_starrc/bin/grdgenxo
CALIBRE_TOOL ?= /opt/mentor/calibre2025/aok_cal_2025.1_16.10/bin/calibre
CALIBREDRV_TOOL ?= /opt/mentor/calibre2025/aok_cal_2025.1_16.10/bin/calibredrv
V2LVS_TOOL ?= /opt/mentor/calibre2025/aok_cal_2025.1_16.10/pkgs/icv.aok/bin/v2lvs
PT_TOOL ?= /opt/synopsys/prime/W-2024.09-SP3/bin/pt_shell
FM_TOOL ?= /opt/synopsys/fm/W-2024.09-SP3/bin/fm_shell
TMAX_TOOL ?= /opt/synopsys/testmax/W-2024.09-SP1/bin/tmax

b ?= spi_slave
export DESIGN_NAME = $(b)
export ROOT_PATH   = $(CURDIR)
export RUN_PATH    = $(CURDIR)

UTIL    = $(ROOT_PATH)/scripts/utilities
PNR     = $(ROOT_PATH)/scripts/pnr
SIGNOFF = $(ROOT_PATH)/scripts/signoff

BE_ROOT ?= $(abspath $(CURDIR)/../be_env)
PDK_ROOT ?= $(HOME)/PDK
DESIGN_SRC_ROOT ?= $(abspath $(CURDIR)/../DESIGN)

export FC_TOOL DC_TOOL TCLSH_TOOL LM_TOOL STARRC_TOOL GRDGEN_TOOL CALIBRE_TOOL CALIBREDRV_TOOL V2LVS_TOOL
export PT_TOOL FM_TOOL TMAX_TOOL
export BE_ROOT PDK_ROOT DESIGN_SRC_ROOT
export UTIL PNR SIGNOFF

STAGES = run_floorplan run_power_mesh run_place run_cts run_route run_chip_finish \
         run_metal_fill run_fm run_hold_fix_eco run_setup_fix_eco run_fc_drc_lvs \
         run_merge_gds run_starrc run_drc run_antenna run_lvs run_pt_signoff \
         run_atpg_postlayout
export STAGES

ifneq (,$(filter pnr_all pnr_eco_all signoff_all,$(MAKECMDGOALS)))
export FC_AUTO_EXIT := 1
endif

define run_stage
	@bash $(UTIL)/stage_execute.sh $(1)
endef

.DEFAULT_GOAL := status
.NOTPARALLEL:

.PHONY: status link clean pnr_all pnr_eco_all signoff_all
.PHONY: run_prepare_inputs run_floorplan run_power_mesh run_place run_cts
.PHONY: run_route run_chip_finish run_metal_fill run_fc_drc_lvs run_merge_gds
.PHONY: run_extract_spef run_starrc run_starrc_spef run_drc run_antenna run_lvs
.PHONY: drc_gui lvs_gui ant_gui fc_gui run_pt_signoff run_fm
.PHONY: run_atpg_postlayout run_hold_fix_eco run_setup_fix_eco

status:
	@bash $(UTIL)/stage_status.sh

link:
	@bash $(UTIL)/inputs_link.sh

run_prepare_inputs: link
	@bash $(UTIL)/inputs_prepare.sh

run_floorplan: link
	$(call run_stage,run_floorplan)

run_power_mesh: link
	$(call run_stage,run_power_mesh)

run_place: link
	$(call run_stage,run_place)

run_cts: link
	$(call run_stage,run_cts)

run_route: link
	$(call run_stage,run_route)

run_chip_finish: link
	$(call run_stage,run_chip_finish)

run_metal_fill: link
	$(call run_stage,run_metal_fill)

run_fc_drc_lvs: link
	$(call run_stage,run_fc_drc_lvs)

fc_gui: link
	@bash $(UTIL)/layout_launch.sh

run_merge_gds: link
	$(call run_stage,run_merge_gds)
	@bash $(UTIL)/gds_clean.sh $(DESIGN_NAME)/results/$(DESIGN_NAME).pnr.mapped.gds
	@bash $(UTIL)/file_check.sh $(DESIGN_NAME)/results/$(DESIGN_NAME).pnr.mapped.gds

pnr_all: run_floorplan run_power_mesh run_place run_cts run_route run_chip_finish run_fm
	@bash $(UTIL)/completion_report.sh pnr

pnr_eco_all: run_hold_fix_eco run_chip_finish run_fm
	@bash $(UTIL)/completion_report.sh pnr_eco

run_starrc_spef: link
	@bash $(UTIL)/file_check.sh $(DESIGN_NAME)/results/$(DESIGN_NAME).pnr.def.gz
	@bash $(SIGNOFF)/parasitic_extract.sh

run_starrc: run_starrc_spef

run_extract_spef: run_starrc_spef

run_drc: link run_merge_gds
	@bash $(SIGNOFF)/verification_config.sh drc
	@bash $(SIGNOFF)/verification_run.sh drc

run_antenna: link run_merge_gds
	@bash $(SIGNOFF)/verification_config.sh drc
	@bash $(SIGNOFF)/verification_run.sh antenna

run_lvs: link run_merge_gds
	@bash $(SIGNOFF)/logical_netlist.sh
	@bash $(SIGNOFF)/cell_cdl.sh
	@bash $(SIGNOFF)/lvs_netlist.sh
	@bash $(SIGNOFF)/verification_config.sh lvs
	@bash $(SIGNOFF)/verification_run.sh lvs

drc_gui:
	@bash $(SIGNOFF)/verification_view.sh drc

lvs_gui:
	@bash $(SIGNOFF)/verification_view.sh lvs

ant_gui:
	@bash $(SIGNOFF)/verification_view.sh antenna

run_pt_signoff: run_extract_spef
	@bash $(SIGNOFF)/timing_signoff.sh

run_fm: link
	@bash $(UTIL)/file_check.sh $(DESIGN_NAME)/results/$(DESIGN_NAME).pnr.v
	@bash $(UTIL)/file_check.sh $(DESIGN_NAME)/inputs/$(DESIGN_NAME).scan.v
	@bash $(SIGNOFF)/equivalence_check.sh

signoff_all: run_metal_fill run_fc_drc_lvs run_merge_gds run_extract_spef run_drc run_antenna run_lvs run_pt_signoff run_atpg_postlayout
	@bash $(UTIL)/completion_report.sh signoff

run_atpg_postlayout: link
	@bash $(UTIL)/file_check.sh $(DESIGN_NAME)/results/$(DESIGN_NAME).pnr.v
	@bash $(SIGNOFF)/layout_patterns.sh

run_hold_fix_eco: link
	$(call run_stage,run_hold_fix_eco)

run_setup_fix_eco: link
	$(call run_stage,run_setup_fix_eco)

clean:
	@bash $(UTIL)/outputs_clean.sh

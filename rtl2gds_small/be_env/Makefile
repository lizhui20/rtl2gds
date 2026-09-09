SHELL         := /bin/bash
.SHELLFLAGS   := -e -o pipefail -c
DC_TOOL       = /opt/synopsys/syn/W-2024.09-SP3/bin/dcnxt_shell
FM_TOOL       = /opt/synopsys/fm/W-2024.09-SP3/bin/fm_shell
PT_TOOL       = /opt/synopsys/prime/W-2024.09-SP3/bin/pt_shell
VC_TOOL       = /opt/synopsys/vc_static/W-2024.09-SP2/bin/vc_static_shell
LC_TOOL       ?= /opt/synopsys/lc/W-2024.09-SP3/bin/lc_shell
FC_TOOL       = /opt/synopsys/fusioncompiler/W-2024.09-SP3/bin/fc_shell
TMAX_TOOL     = /opt/synopsys/testmax/W-2024.09-SP1/bin/tmax

LM_TOOL       ?= /opt/synopsys/syn/W-2024.09-SP3/icc2/bin/lm_shell
export FC_TOOL

export SYNOPSYS_LC_ROOT=$(abspath $(dir $(LC_TOOL))/..)

export DESIGN_NAME=$(b)
export ROOT_PATH=$(shell pwd)
export RUN_PATH=$(shell pwd)
export PDK_ROOT ?= $(HOME)/PDK

.PHONY: @status run_prepare_inputs run_vc_lint run_vc_cdc run_vc_rdc
.PHONY: run_fc_syn run_fm run_fm_dft run_pt run_gen_ndm run_gca
.PHONY: run_dft_insert run_atpg run_testmax_dft clean @clean_ALL

@status :
	@echo "Usage: gmake EDA_TOOL b=XXX"
	@$(ROOT_PATH)/scripts/utilities/target_list.pl


run_prepare_inputs :
	date > $@.start;\
	mkdir -p pdk ;\
	ln -sfn "$(PDK_ROOT)/tsmc28hpcplus" pdk/tsmc28hpcplus ;\
	mkdir -p $(DESIGN_NAME)
	cd $(DESIGN_NAME);\
	mkdir -p inputs results logs reports ref tech work ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(FC_TOOL) -output_log_file ../logs/$@.log -f $(ROOT_PATH)/scripts/utilities/inputs_build.tcl ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	#mv $@.start $@

run_vc_lint:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(VC_TOOL) -full64 -f $(ROOT_PATH)/scripts/vc/rtl_check.tcl -output_log_file ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@


run_vc_cdc:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(VC_TOOL) -full64 -f $(ROOT_PATH)/scripts/vc/crossing_check.tcl -output_log_file ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_vc_rdc:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(VC_TOOL) -full64 -f $(ROOT_PATH)/scripts/vc/reset_check.tcl -output_log_file ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_fc_syn:run_prepare_inputs 
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(FC_TOOL) -output_log_file ../logs/$@.log -f $(ROOT_PATH)/scripts/fc_syn/synthesis_main.tcl ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_fm:
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(FM_TOOL) -file $(ROOT_PATH)/scripts/fm/equivalence_check.tcl |& tee -i ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_fm_dft:run_dft_insert
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(FM_TOOL) -file $(ROOT_PATH)/scripts/fm/scan_equivalence.tcl |& tee -i ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_pt:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(PT_TOOL) -file $(ROOT_PATH)/scripts/pt/timing_main.tcl |& tee -i ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs ;\
	bash $(ROOT_PATH)/scripts/utilities/library_compile.sh "$(LC_TOOL)"
	date >> $@.start
	#mv $@.start $@
run_gen_ndm:
	cd $(DESIGN_NAME) ;\
	cd work ;\
	$(LM_TOOL) -output_log_file ../logs/run_gen_ndm.log -file $(ROOT_PATH)/scripts/pt/abstract_build.tcl ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/run_gen_ndm.log ../logs

run_gca:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(PT_TOOL) -constraints -no_gui -file $(ROOT_PATH)/scripts/pt/constraint_audit.tcl |& tee -i ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	#mv $@.start $@

run_dft_insert:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(DC_TOOL) -output_log_file ../logs/$@.log -f $(ROOT_PATH)/scripts/dft/scan_insert.tcl ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_atpg:run_prepare_inputs
	date > $@.start
	cd $(DESIGN_NAME) ;\
	ln -sf ./$@.log ./logs/latest.log ;\
	cd work ;\
	$(TMAX_TOOL) -shell -64 $(ROOT_PATH)/scripts/dft/pattern_generate.tcl |& tee -i ../logs/$@.log ;\
	python3 $(ROOT_PATH)/scripts/utilities/log_review.py ../logs/$@.log ../logs
	date >> $@.start
	mv $@.start $@

run_testmax_dft:run_dft_insert run_atpg
	@echo "TestMAX DFT flow done (scan insertion + ATPG)"

clean:
	rm -rf default*.svf *command.log *output.txt tmp.*
	rm -rf reports/ logs/* formality.log sg_shell.log
	rm -rf tmp.tcl ./inputs/my_set_* ./inputs/*list ./inputs/*.gen ./inputs/*.pt ./inputs/*uns*
	rm -rf *dc_syn_*_design* run_*  dc_syn_gen_sdc dc_syn_gen_upf  icc2_view_hier 
	rm -rf WORK formality* FM_WORK
	rm -rf verdiLog vcst_* novas*
	rm -rf uns
	rm -rf check_design* dcg_* set_clock_uncertainty* compile init_design

@clean_ALL:
	rm -rf default*.svf *command.log *output.txt tmp.*
	rm -rf reports/ logs/* formality.log sg_shell.log
	rm -rf tmp.tcl ./inputs/my_set_* ./inputs/*list ./inputs/*.gen ./inputs/*.pt ./inputs/*uns*
	rm -rf *dc_syn_*_design* run_* dc_syn_gen_sdc dc_syn_gen_upf icc2_view_hier
	rm -rf results/* WORK *_LIB work* formality* FM_WORK
	rm -rf uns

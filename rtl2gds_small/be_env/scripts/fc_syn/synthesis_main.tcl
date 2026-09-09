puts "Start run fusion compiler physical synthesis, [date]"

source -e -v $env(ROOT_PATH)/scripts/utilities/project_context.tcl

rm_source -file ${root_path}/scripts/fc_syn/synthesis_import.tcl
rm_source -file ${root_path}/scripts/fc_syn/synthesis_constraints.tcl
rm_source -file ${root_path}/scripts/fc_syn/synthesis_optimize.tcl
rm_source -file ${root_path}/scripts/fc_syn/synthesis_export.tcl

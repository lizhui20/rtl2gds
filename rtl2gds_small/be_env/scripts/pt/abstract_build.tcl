set DESIGN_NAME "$env(DESIGN_NAME)"
set run_path    "$env(RUN_PATH)/${DESIGN_NAME}"

set results_ndm "${run_path}/results/${DESIGN_NAME}.gen_ndm"
set results     "${run_path}/results"
sh mkdir -p     $results_ndm

set tech [lindex [glob ${run_path}/tech/*.tf] 0]
create_workspace Workspace_${DESIGN_NAME} -technology $tech
read_lef ${results}/${DESIGN_NAME}.lef
read_db ${results}/${DESIGN_NAME}.db
check_workspace
commit_workspace -force -output ${results_ndm}/${DESIGN_NAME}.ndm

#if {$EXIT_STATUS == 1} {
    exit
#}

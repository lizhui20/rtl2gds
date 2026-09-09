#!/usr/bin/env bash
set -euo pipefail

stage=${1:?usage: stage_execute.sh <stage>}
design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
fc_tool=${FC_TOOL:-fc_shell}
pnr_dir=${PNR:-${root}/scripts/pnr}
util_dir=${UTIL:-${root}/scripts/utilities}
run=${root}/${design}

case "$stage" in
  run_chip_finish) stage_script=layout_export.tcl ;;
  run_cts) stage_script=clock_tree.tcl ;;
  run_fc_drc_lvs) stage_script=layout_check.tcl ;;
  run_floorplan) stage_script=floorplan_build.tcl ;;
  run_hold_fix_eco) stage_script=hold_repair.tcl ;;
  run_merge_gds) stage_script=gds_merge.tcl ;;
  run_metal_fill) stage_script=metal_fill.tcl ;;
  run_place) stage_script=placement.tcl ;;
  run_power_mesh) stage_script=power_grid.tcl ;;
  run_route) stage_script=routing.tcl ;;
  run_setup_fix_eco) stage_script=setup_repair.tcl ;;
  *) echo "ERROR: unknown layout stage: $stage" >&2; exit 1 ;;
esac

mkdir -p "${run}/results" "${run}/logs" "${run}/reports" "${run}/work"

rm -f "${run}/logs/${stage}.done"

(
  cd "${run}/work"
  "${fc_tool}" -output_log_file "../logs/${stage}.log" -f "${pnr_dir}/${stage_script}"
)

python3 "${util_dir}/log_review.py" "${run}/logs/${stage}.log" "${run}/logs"

if ! grep -q "Completed ${stage_script}" "${run}/logs/${stage}.log"; then
  echo "ERROR: stage ${stage} did not complete -- see ${run}/logs/${stage}.log" >&2
  exit 1
fi

date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/${stage}.done"

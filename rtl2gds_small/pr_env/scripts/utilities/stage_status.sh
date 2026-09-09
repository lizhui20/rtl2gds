#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
run=${root}/${design}
stages=${STAGES:-"run_floorplan run_power_mesh run_place run_cts run_route run_chip_finish run_metal_fill run_fm run_hold_fix_eco run_setup_fix_eco run_fc_drc_lvs run_merge_gds run_starrc run_drc run_antenna run_lvs run_pt_signoff run_atpg_postlayout"}

echo "Usage: gmake EDA_TOOL b=<design>"
echo "Design: ${design}   stage status:"
for stage in ${stages}; do
  stamp=${run}/logs/${stage}.done
  if [ -f "${stamp}" ]; then
    printf "  [DONE] %-16s %s\n" "${stage}" "$(cat "${stamp}")"
  else
    printf "  [ -- ] %-16s %s\n" "${stage}" "not run"
  fi
done

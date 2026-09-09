#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
tmax_tool=${TMAX_TOOL:-tmax}
signoff=${SIGNOFF:-${root}/scripts/signoff}
util=${UTIL:-${root}/scripts/utilities}
run=${root}/${design}
logs=${run}/logs/signoff
results=${run}/results/signoff
reports=${run}/reports/signoff

mkdir -p "${run}/work" "${logs}" "${results}" "${reports}"
bash "${signoff}/scan_protocol.sh"
(
  set -o pipefail
  cd "${run}/work"
  "${tmax_tool}" -shell -64 "${signoff}/layout_patterns.tcl" 2>&1 | tee "${logs}/run_atpg_postlayout.log"
)

python3 "${util}/log_review.py" "${logs}/run_atpg_postlayout.log" "${logs}"
date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_atpg_postlayout.done"

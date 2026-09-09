#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
fm_tool=${FM_TOOL:-fm_shell}
signoff=${SIGNOFF:-${root}/scripts/signoff}
util=${UTIL:-${root}/scripts/utilities}
run=${root}/${design}
work=${run}/work/signoff
results=${run}/results/signoff
reports=${run}/reports/signoff
logs=${run}/logs/signoff

mkdir -p "${work}" "${results}" "${reports}" "${logs}"
(
  set -o pipefail
  cd "${work}"
  "${fm_tool}" -file "${signoff}/layout_equivalence.tcl" 2>&1 | tee "${logs}/run_fm.log"
)

python3 "${util}/log_review.py" "${logs}/run_fm.log" "${logs}"
date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_fm.done"

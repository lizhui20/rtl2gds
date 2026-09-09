#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
pt_tool=${PT_TOOL:-pt_shell}
signoff=${SIGNOFF:-${root}/scripts/signoff}
util=${UTIL:-${root}/scripts/utilities}
run=${root}/${design}
work=${run}/work/signoff
logs=${run}/logs/signoff
reports=${run}/reports/signoff

mkdir -p "${logs}"
rm -f "${run}/logs/run_pt_signoff.done"
(
  set -o pipefail
  cd "${work}"
  "${pt_tool}" -file "${signoff}/timing_analysis.tcl" 2>&1 | tee "${logs}/run_pt_signoff.log"
)

python3 "${util}/log_review.py" "${logs}/run_pt_signoff.log" "${logs}"
date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_pt_signoff.done"

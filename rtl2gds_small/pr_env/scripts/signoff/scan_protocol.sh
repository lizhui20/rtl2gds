#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
dc_tool=${DC_TOOL:-dcnxt_shell}
signoff=${SIGNOFF:-${root}/scripts/signoff}
util=${UTIL:-${root}/scripts/utilities}
run=${root}/${design}
logs=${run}/logs/signoff
work=${run}/work/signoff

mkdir -p "${logs}" "${work}"
"${dc_tool}" -output_log_file "${logs}/make_atpg_postlayout_spf.log" \
  -f "${signoff}/scan_protocol.tcl"

python3 "${util}/log_review.py" "${logs}/make_atpg_postlayout_spf.log" "${logs}"

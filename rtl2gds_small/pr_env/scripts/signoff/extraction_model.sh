#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
lm_tool=${LM_TOOL:-lm_shell}
starrc_tool=${STARRC_TOOL:-StarXtract}

run=${root}/${design}
work=${run}/work/signoff
starrc_work=${work}/starrc
results=${run}/results/signoff
reports=${run}/reports/signoff
logs=${run}/logs/signoff
signoff=${root}/scripts/signoff
util=${root}/scripts/utilities

mkdir -p "${starrc_work}/run" "${results}" "${reports}" "${logs}"

RC_CORNER=mmcm "${lm_tool}" -file "${signoff}/extraction_config.tcl"

set -o pipefail
(
  cd "${starrc_work}/run"
  "${starrc_tool}" "../${design}.mmcm.cmd" 2>&1 | tee "${logs}/run_starrc_mmcm.log"
)

if [ -s "${results}/${design}.spef.cworst" ]; then
  cp "${results}/${design}.spef.cworst" "${results}/${design}.cworst.spef"
fi
if [ -s "${results}/${design}.spef.cbest" ]; then
  cp "${results}/${design}.spef.cbest" "${results}/${design}.cbest.spef"
fi

test -s "${results}/${design}.cworst.spef"
test -s "${results}/${design}.cbest.spef"
cp "${results}/${design}.cworst.spef" "${results}/${design}.spef"

python3 "${util}/log_review.py" "${logs}/run_starrc_mmcm.log" "${logs}"
test -s "${results}/${design}.spef"
date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_starrc.done"

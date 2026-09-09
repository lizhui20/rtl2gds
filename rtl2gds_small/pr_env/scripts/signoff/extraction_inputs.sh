#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
source "${root}/scripts/utilities/config_load.sh"
grdgen_tool=${GRDGEN_TOOL:-grdgenxo}

run=${root}/${design}
starrc_work=${run}/work/signoff/starrc
results=${run}/results/signoff
reports=${run}/reports/signoff
util=${root}/scripts/utilities

mkdir -p "${starrc_work}" "${results}" "${reports}"

def_gz=${run}/results/${design}.pnr.def.gz
def_out=${starrc_work}/${design}.pnr.def
test -s "${def_gz}"
gzip -cd "${def_gz}" > "${def_out}"
test -s "${def_out}"

if [ "${PDK_PROFILE:-}" != "tsmc28hpcplus" ]; then
  exit 0
fi

common_env=(
  SIGNOFF_WORK="${run}/work/signoff"
  GRDGEN_TOOL="${grdgen_tool}"
)

env "${common_env[@]}" \
  N28_GRID_CORNER=cworst \
  N28_NXTGRD_TARGET="${starrc_work}/tsmcn28_9lm_cworst.nxtgrd" \
  bash "${util}/rc_grid.sh"

env "${common_env[@]}" \
  N28_GRID_CORNER=cbest \
  N28_NXTGRD_TARGET="${starrc_work}/tsmcn28_9lm_cbest.nxtgrd" \
  bash "${util}/rc_grid.sh"

test -s "${starrc_work}/tsmcn28_9lm_cworst.nxtgrd"
test -s "${starrc_work}/tsmcn28_9lm_cbest.nxtgrd"

#!/usr/bin/env bash
set -euo pipefail

corner=${N28_GRID_CORNER:?N28_GRID_CORNER is required: cworst or cbest}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
design=${DESIGN_NAME:?DESIGN_NAME is required}
source "${root}/scripts/utilities/config_load.sh"
run=${root}/${design}
signoff_work=${SIGNOFF_WORK:-${run}/work/signoff}
grdgen_tool=${GRDGEN_TOOL:-grdgenxo}
tech=${run}/tech
pdk_rc=${root}/pdk/tsmc28hpcplus/installed/tech/rc_1p9m_4x2y2r
tlu_base=cln28hpc+_1p09m+ut-alrdl_4x2y2r

case "${corner}" in
  cworst)
    src_itf=${pdk_rc}/${tlu_base}_cworst_T.itf
    pdk_grid=${pdk_rc}/${tlu_base}_cworst_T.nxtgrd
    linked_grid=${tech}/tsmcn28_9lm_cworst.nxtgrd
    generated_grid=${signoff_work}/starrc/${tlu_base}_cworst_T.nxtgrd
    local_itf=${tlu_base}_cworst_T.itf
    target=${N28_NXTGRD_TARGET:-${signoff_work}/starrc/tsmcn28_9lm_cworst.nxtgrd}
    ;;
  cbest)
    src_itf=${pdk_rc}/${tlu_base}_cbest.itf
    pdk_grid=${pdk_rc}/${tlu_base}_cbest.nxtgrd
    linked_grid=${tech}/tsmcn28_9lm_cbest.nxtgrd
    generated_grid=${signoff_work}/starrc/${tlu_base}_cbest.nxtgrd
    local_itf=${tlu_base}_cbest.itf
    target=${N28_NXTGRD_TARGET:-${signoff_work}/starrc/tsmcn28_9lm_cbest.nxtgrd}
    ;;
  *)
    echo "ERROR: N28_GRID_CORNER must be cworst or cbest, got ${corner}" >&2
    exit 1
    ;;
esac

mkdir -p "${signoff_work}/starrc"
if [ -s "${linked_grid}" ]; then
  ln -sfn "${linked_grid}" "${target}"
elif [ -s "${pdk_grid}" ]; then
  ln -sfn "${pdk_grid}" "${target}"
else
  grdgen_executable=$(command -v -- "$grdgen_tool")
  grdgen_platform=$(cd -- "$(dirname -- "$(readlink -f -- "$grdgen_executable")")/.." && pwd)
  ld_path=${grdgen_platform}/lib:${grdgen_platform}/lib/shlib
  test -s "${src_itf}"
  cp "${src_itf}" "${signoff_work}/starrc/${local_itf}"
  (cd "${signoff_work}/starrc" && LD_LIBRARY_PATH="${ld_path}" "${grdgen_tool}" "${local_itf}")
  if [ -s "${generated_grid}" ]; then
    ln -sfn "${generated_grid}" "${target}"
  fi
fi

test -s "${target}"

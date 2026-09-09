#!/usr/bin/env bash
set -euo pipefail

mode=${1:?usage: verification_view.sh drc|lvs|antenna}
design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
calibre_tool=${CALIBRE_TOOL:-calibre}
run=${root}/${design}
work=${run}/work/signoff/calibre
results=${run}/results/signoff

case "${mode}" in
  drc)
    args=(-rve -drc "${results}/${design}.drc.results")
    ;;
  lvs)
    args=(-rve -lvs "${results}/svdb")
    ;;
  antenna)
    args=(-rve -drc "${results}/${design}.ant.results")
    ;;
  *)
    echo "ERROR: unsupported Calibre RVE mode: ${mode}" >&2
    exit 1
    ;;
esac

cd "${work}"
MGC_TMPDIR=/tmp "${calibre_tool}" "${args[@]}"

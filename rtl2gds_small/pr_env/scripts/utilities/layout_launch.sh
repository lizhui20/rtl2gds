#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
fc_tool=${FC_TOOL:-fc_shell}
pnr_dir=${PNR:-${root}/scripts/pnr}
run=${root}/${design}

mkdir -p "${run}/work"
(
  cd "${run}/work"
  "${fc_tool}" -f "${pnr_dir}/layout_view.tcl"
)

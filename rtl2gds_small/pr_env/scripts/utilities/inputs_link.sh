#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_PATH:?ROOT_PATH is required}
be_root=${BE_ROOT:-${root}/../be_env}
pdk_root=${PDK_ROOT:-${HOME}/PDK}
design_src_root=${DESIGN_SRC_ROOT:-${root}/../DESIGN}
tclsh_tool=${TCLSH_TOOL:-tclsh8.6}

BE_ROOT="${be_root}" PDK_ROOT="${pdk_root}" DESIGN_SRC_ROOT="${design_src_root}" \
  "${tclsh_tool}" "${root}/scripts/utilities/design_links.tcl"

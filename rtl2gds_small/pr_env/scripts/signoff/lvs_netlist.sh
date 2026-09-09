#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
design=${DESIGN_NAME:?DESIGN_NAME is required}
source "${root}/scripts/utilities/config_load.sh"
run=${root}/${design}
logical_v=${CALIBRE_LOGICAL_V:-${run}/results/signoff/${design}.lvs.logical.v}
std_cdl=${CALIBRE_STD_CDL:-${run}/results/signoff/stdcells.calibre.spi}
source_sp=${LVS_SOURCE_SP:-${run}/results/signoff/${design}.source.sp}
report_log=${V2LVS_LOG:-${run}/logs/signoff/v2lvs.log}
v2lvs_tool=${V2LVS_TOOL:-v2lvs}

mkdir -p "$(dirname "${source_sp}")" "$(dirname "${report_log}")"
MGC_TMPDIR=/tmp "${v2lvs_tool}" \
  -v "${logical_v}" \
  -lsp "${std_cdl}" \
  -s "${std_cdl}" \
  -s0 VSS \
  -s1 VDD \
  -o "${source_sp}" \
  -log "${report_log}"

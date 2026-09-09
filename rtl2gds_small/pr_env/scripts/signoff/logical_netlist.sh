#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
design=${DESIGN_NAME:?DESIGN_NAME is required}
source "${root}/scripts/utilities/config_load.sh"
pdk_profile=${PDK_PROFILE:-}
run=${root}/${design}
src=${PNR_V:-${run}/results/${design}.pnr.v}
lvs_src=${PNR_LVS_V:-${run}/results/${design}.pnr.lvs.v}
source_mode=${CALIBRE_LVS_SOURCE_NETLIST:-logical}
out=${CALIBRE_LOGICAL_V:-${run}/results/signoff/${design}.lvs.logical.v}

mkdir -p "$(dirname "${out}")"

if [ "${pdk_profile}" = "tsmc28hpcplus" ]; then
  case "${source_mode}" in
    logical)
      ;;
    physical)
      if [ -z "${lvs_src}" ] || [ ! -s "${lvs_src}" ]; then
        echo "ERROR: CALIBRE_LVS_SOURCE_NETLIST=physical but PNR_LVS_V is missing or empty: ${lvs_src}" >&2
        exit 1
      fi
      src=${lvs_src}
      ;;
    *)
      echo "ERROR: CALIBRE_LVS_SOURCE_NETLIST must be logical or physical, got '${source_mode}'" >&2
      exit 1
      ;;
  esac
  cp "${src}" "${out}"
else
  sed -E '/^FILL(1|2|4|8|16|32|64)[[:space:]]/d' "${src}" > "${out}"
  ! grep -Eq '^FILL(1|2|4|8|16|32|64)[[:space:]]' "${out}"
fi

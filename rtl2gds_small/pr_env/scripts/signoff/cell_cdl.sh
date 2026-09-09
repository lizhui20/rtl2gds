#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
design=${DESIGN_NAME:?DESIGN_NAME is required}
source "${root}/scripts/utilities/config_load.sh"
pdk_profile=${PDK_PROFILE:-}
run=${root}/${design}

case "${pdk_profile}" in
  tsmc28hpcplus)
    default_src=${run}/ref/tsmc28_7t_all.spi
    ;;
  smic18)
    default_src=${run}/ref/smic18.cdl
    ;;
  *)
    echo "ERROR: unsupported PDK_PROFILE for Calibre std CDL: ${pdk_profile}" >&2
    exit 1
    ;;
esac

src=${STD_CDL:-${default_src}}
out=${CALIBRE_STD_CDL:-${run}/results/signoff/stdcells.calibre.spi}

mkdir -p "$(dirname "${out}")"

if [ "${pdk_profile}" = "tsmc28hpcplus" ]; then
  python3 "${root}/scripts/utilities/spice_deduplicate.py" "${src}" "${out}"
else
  sed -E \
    -e '/^\.OPTION SCALE 1e-6$/d' \
    -e 's/\<GND\>/VSS/g' \
    -e '/^[Mm]/s/[[:space:]]N[[:space:]]+L=/ n18 L=/' \
    -e '/^[Mm]/s/[[:space:]]P[[:space:]]+L=/ p18 L=/' \
    "${src}" > "${out}"
fi

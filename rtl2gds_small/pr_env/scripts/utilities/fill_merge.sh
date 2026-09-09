#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
calibredrv_tool=${CALIBREDRV_TOOL:-calibredrv}

run=${root}/${design}
work=${run}/work/signoff/calibre
results=${run}/results/signoff
original_gds=${run}/results/${design}.pnr.mapped.gds
dummy_raw_gds=${work}/${design}.pnr.dummy.generated.gds
dummy_merged_gds=${results}/${design}.pnr.dummy.gds
merged_top=merge_${design}
merge_tcl=${work}/merge_n28_dummy_gds.tcl

for f in "${original_gds}" "${dummy_raw_gds}"; do
  if [ ! -s "${f}" ]; then
    echo "ERROR: missing GDS for N28 dummy merge: ${f}" >&2
    exit 1
  fi
done
if [ ! -x "${calibredrv_tool}" ]; then
  echo "ERROR: calibredrv not executable: ${calibredrv_tool}" >&2
  exit 1
fi

mkdir -p "${work}" "${results}"
rm -f "${dummy_merged_gds}"

{
  printf 'set original_gds {%s}\n' "${original_gds}"
  printf 'set dummy_raw_gds {%s}\n' "${dummy_raw_gds}"
  printf 'set dummy_merged_gds {%s}\n' "${dummy_merged_gds}"
  printf 'set design {%s}\n' "${design}"
  printf 'set merged_top {%s}\n' "${merged_top}"
  printf 'layout filemerge -in $original_gds -in $dummy_raw_gds -out $dummy_merged_gds -mode append\n'
  printf 'set L [layout create $dummy_merged_gds -dt_expand -preservePaths -preserveTextAttributes -preserveProperties -noReport]\n'
  printf '$L cellname $design $merged_top\n'
  printf '$L gdsout $dummy_merged_gds\n'
  printf 'exit\n'
} > "${merge_tcl}"

"${calibredrv_tool}" -64 "${merge_tcl}"

if [ ! -s "${dummy_merged_gds}" ]; then
  echo "ERROR: CalibreDRV did not create merged dummy GDS: ${dummy_merged_gds}" >&2
  exit 1
fi

echo "N28 Calibre dummy merged GDS: ${dummy_merged_gds}"
echo "N28 Calibre dummy merged top: ${merged_top}"

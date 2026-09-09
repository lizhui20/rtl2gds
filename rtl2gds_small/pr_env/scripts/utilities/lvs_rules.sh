#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
source "${root}/scripts/utilities/config_load.sh"
power_net=${N28_POWER_NET:-VDD}
ground_net=${N28_GROUND_NET:-VSS}

run=${root}/${design}
out=${run}/work/signoff/calibre
results=${run}/results/signoff
reports=${run}/reports/signoff
gds=${run}/results/${design}.pnr.mapped.gds
source_sp=${results}/${design}.source.sp

lvs_in=${run}/tech/DFM_LVS_RC_CALIBRE_N28HP_1p9m_ALRDL.v1.0_3o
dfm_dir=${run}/tech/DFM
runset=${out}/lvs.runset

for file in "${gds}" "${source_sp}" "${lvs_in}"; do
  if [ ! -s "${file}" ]; then
    echo "ERROR: missing N28 LVS input: ${file}" >&2
    exit 1
  fi
done
if [ ! -d "${dfm_dir}" ]; then
  echo "ERROR: missing N28 LVS DFM directory: ${dfm_dir}" >&2
  exit 1
fi

mkdir -p "${out}" "${results}" "${reports}"
ln -sfn "${dfm_dir}" "${out}/DFM"

sed \
  -e 's|^//#define HPC_PLUS_PROCESS|#define HPC_PLUS_PROCESS|' \
  -e 's|^//#define STD_LIB|#define STD_LIB|' \
  -e "s|^LAYOUT PRIMARY .*|LAYOUT PRIMARY \"${design}\"|" \
  -e "s|^LAYOUT PATH .*|LAYOUT PATH \"${gds}\"|" \
  -e "s|^SOURCE PRIMARY .*|SOURCE PRIMARY \"${design}\"|" \
  -e "s|^SOURCE PATH .*|SOURCE PATH \"${source_sp}\"|" \
  -e "s|^LVS REPORT \".*|LVS REPORT \"${reports}/${design}.lvs.report\"|" \
  -e "s|^  MASK SVDB DIRECTORY .* QUERY|  MASK SVDB DIRECTORY \"${results}/svdb\" QUERY|" \
  -e "s|^VARIABLE POWER_NAME .*|VARIABLE POWER_NAME  \"${power_net}\"|" \
  -e "s|^VARIABLE GROUND_NAME .*|VARIABLE GROUND_NAME  \"${ground_net}\"|" \
  -e 's|^VIRTUAL CONNECT COLON YES|VIRTUAL CONNECT COLON NO|' \
  -e 's|^LVS IGNORE PORTS[[:space:]]*NO|LVS IGNORE PORTS                 YES\nLVS GLOBALS ARE PORTS             NO|' \
  -e 's|^LVS CHECK PORT NAMES[[:space:]]*YES|LVS CHECK PORT NAMES             NO|' \
  "${lvs_in}" > "${runset}"

grep -q "^LAYOUT PATH \"${gds}\"" "${runset}" || {
  echo "ERROR: failed to rewrite LAYOUT PATH in ${runset}" >&2
  exit 1
}
grep -q "^SOURCE PATH \"${source_sp}\"" "${runset}" || {
  echo "ERROR: failed to rewrite SOURCE PATH in ${runset}" >&2
  exit 1
}
grep -q "^VARIABLE POWER_NAME  \"${power_net}\"" "${runset}" || {
  echo "ERROR: failed to set LVS power net in ${runset}" >&2
  exit 1
}
grep -q "^VARIABLE GROUND_NAME  \"${ground_net}\"" "${runset}" || {
  echo "ERROR: failed to set LVS ground net in ${runset}" >&2
  exit 1
}

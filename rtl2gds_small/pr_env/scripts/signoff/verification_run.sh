#!/usr/bin/env bash
set -euo pipefail

mode=${1:?usage: verification_run.sh drc|antenna|lvs}
design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
source "${root}/scripts/utilities/config_load.sh"
pdk_profile=${PDK_PROFILE:-}
n28_drc_mode=${N28_DRC_MODE:-block}
enable_calibre_dummy_fill=${ENABLE_CALIBRE_DUMMY_FILL:-1}
calibre_tool=${CALIBRE_TOOL:-calibre}

run=${root}/${design}
work=${run}/work/signoff/calibre
logs=${run}/logs/signoff
reports=${run}/reports/signoff
util=${root}/scripts/utilities

mkdir -p "${logs}"

run_calibre_drc() {
  local runset=$1
  local log=$2
  local tee_mode=${3:-replace}
  if [ "${tee_mode}" = "append" ]; then
    (cd "${work}" && MGC_TMPDIR=/tmp "${calibre_tool}" -drc -hier -turbo 8 "${runset}" | tee -a "${log}")
  else
    (cd "${work}" && MGC_TMPDIR=/tmp "${calibre_tool}" -drc -hier -turbo 8 "${runset}" | tee "${log}")
  fi
}

require_summary_zero() {
  local summary=$1
  local label=$2
  test -s "${summary}" || { echo "ERROR: missing ${label} summary: ${summary}" >&2; exit 1; }
  grep -q 'TOTAL DRC Results Generated:' "${summary}" || {
    echo "ERROR: ${label} summary missing total-result line: ${summary}" >&2
    exit 1
  }
  ! grep -Eq 'TOTAL DRC Results Generated:[[:space:]]+[1-9]' "${summary}" || {
    echo "ERROR: ${label} has nonzero Calibre result count; see ${summary}" >&2
    exit 1
  }
}

require_lvs_clean() {
  local report=$1
  local log=$2
  test -s "${report}" || { echo "ERROR: missing LVS report: ${report}" >&2; exit 1; }

  if grep -Eq '(^|[[:space:]])(INCORRECT|NOT COMPARED)([[:space:]]|$)|LVS completed\. (INCORRECT|NOT COMPARED)' "${report}" "${log}"; then
    echo "ERROR: Calibre LVS did not compare cleanly; see ${report} and ${log}" >&2
    exit 1
  fi
}

require_erc_clean() {
  local summary=$1
  local db=$2
  local log=$3

  if [ -s "${summary}" ] && grep -Eq 'TOTAL ERC RuleCheck Results Generated:[[:space:]]+[1-9]|RULECHECK .* TOTAL Result Count = [1-9]' "${summary}"; then
    echo "ERROR: LVS ERC generated nonzero results; see ${summary} and ${db}" >&2
    exit 1
  fi

  if grep -Eq -- '--- TOTAL RESULTS GENERATED = [1-9]' "${log}"; then
    echo "ERROR: LVS ERC generated nonzero results; see ${summary} and ${db}" >&2
    exit 1
  fi
}

case "${mode}" in
  drc)
    log=${logs}/run_drc.log
    if [ "${pdk_profile}" = "tsmc28hpcplus" ]; then
      echo "N28 Calibre DRC mode: ${n28_drc_mode}" | tee "${log}"
      echo "N28 Calibre dummy fill: ${enable_calibre_dummy_fill}" | tee -a "${log}"
      if [ "${enable_calibre_dummy_fill}" = "1" ]; then
        run_calibre_drc dummy_fill.runset "${log}" append
        "${util}/fill_merge.sh" | tee -a "${log}"
        run_calibre_drc drc_filled.runset "${log}" append
      else
        run_calibre_drc drc.runset "${log}" append
      fi
    else
      run_calibre_drc drc.runset "${log}"
    fi
    python3 "${util}/log_review.py" "${log}" "${logs}"
    if [ "${pdk_profile}" = "tsmc28hpcplus" ]; then
      python3 "${util}/drc_review.py" \
        "${reports}/${design}.drc.summary" \
        "${reports}/${design}.drc.explained_warnings.rpt"
    else
      require_summary_zero "${reports}/${design}.drc.summary" "DRC"
    fi
    date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_drc.done"
    ;;
  antenna)
    log=${logs}/run_antenna.log
    if [ "${pdk_profile}" = "tsmc28hpcplus" ]; then
      echo "N28 Calibre antenna mode: ${n28_drc_mode}" | tee "${log}"
      run_calibre_drc antenna.runset "${log}" append
      run_calibre_drc mim_antenna.runset "${log}" append
      python3 "${util}/log_review.py" "${log}" "${logs}"
      require_summary_zero "${reports}/${design}.ant.summary" "antenna"
      require_summary_zero "${reports}/${design}.mim_ant.summary" "MIM antenna"
    else
      run_calibre_drc antenna.runset "${log}"
      python3 "${util}/log_review.py" "${log}" "${logs}"
      test -s "${reports}/${design}.ant.summary" || { echo "ERROR: missing antenna summary" >&2; exit 1; }
      if grep -E 'RULECHECK .* TOTAL Result Count = [1-9]' "${reports}/${design}.ant.summary" > "${reports}/${design}.ant.violations.rpt"; then
        echo "ERROR: antenna has nonzero Calibre result count; see ${reports}/${design}.ant.violations.rpt" >&2
        exit 1
      else
        rm -f "${reports}/${design}.ant.violations.rpt"
      fi
    fi
    date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_antenna.done"
    ;;
  lvs)
    log=${logs}/run_lvs.log
    (cd "${work}" && MGC_TMPDIR=/tmp "${calibre_tool}" -lvs -hier -turbo 8 lvs.runset | tee "${log}")
    python3 "${util}/log_review.py" "${log}" "${logs}"
    require_lvs_clean "${reports}/${design}.lvs.report" "${log}"
    require_erc_clean "${work}/calibre_erc.sum" "${work}/calibre_erc.db" "${log}"
    date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_lvs.done"
    ;;
  *)
    echo "ERROR: unknown Calibre check mode '${mode}'" >&2
    exit 1
    ;;
esac

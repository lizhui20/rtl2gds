#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
source "${root}/scripts/utilities/config_load.sh"
mode=${N28_DRC_MODE:-block}

run=${root}/${design}
tech=${run}/tech
out=${run}/work/signoff/calibre
results=${run}/results/signoff
reports=${run}/reports/signoff
gds=${run}/results/${design}.pnr.mapped.gds
def=${run}/results/${design}.pnr.def.gz
dummy_raw_gds=${out}/${design}.pnr.dummy.generated.gds
dummy_gds=${results}/${design}.pnr.dummy.gds
dummy_top=merge_${design}
stdcell_names=${out}/stdcell_drc.cells
stdcell_report=${reports}/${design}.drc.stdcell_cells.rpt

drc_in=${tech}/calibre.drc
ant_in=${tech}/CLN28HP_9M.ANT_002.14a
mim_ant_in=${tech}/CLN28HP_9M.MIM_ANT_002.14a
dummy_od_po_tgz=${tech}/Dummy_OD_PO_Calibre_28nm_HP_13a_nopdf.tar.gz
dummy_metal_via_tgz=${tech}/Dummy_Metal_Via_Calibre_28nm_13a_nopdf.tar.gz
enable_dummy=${ENABLE_CALIBRE_DUMMY_FILL:-1}
enable_tcd=${ENABLE_CALIBRE_TCD_FILL:-0}

case "${mode}" in
  block|fullchip) ;;
  *)
    echo "ERROR: N28_DRC_MODE must be block or fullchip, got ${mode}" >&2
    exit 1
    ;;
esac

for deck in "${drc_in}" "${ant_in}" "${mim_ant_in}"; do
  if [ ! -s "${deck}" ]; then
    echo "ERROR: missing N28 Calibre deck: ${deck}" >&2
    echo "       Run 'gmake link b=${design}' so the design-local tech/ links are materialized." >&2
    exit 1
  fi
done
if [ ! -s "${gds}" ]; then
  echo "ERROR: missing mapped GDS: ${gds}" >&2
  exit 1
fi

mkdir -p "${out}" "${results}" "${reports}"

emit_stdcell_cell_file() {
  if [ "${mode}" != "block" ]; then
    return
  fi

  local lef_files=()
  shopt -s nullglob
  lef_files=("${run}"/ref/*.lef)
  shopt -u nullglob

  if [ "${#lef_files[@]}" -eq 0 ]; then
    echo "WARNING: no LEF files found under ${run}/ref; no standard-cell DRC cell list generated" >&2
    return
  fi

  awk '/^MACRO[[:space:]]+/ {print $2}' "${lef_files[@]}" | sort -u > "${stdcell_names}"
  local count
  count=$(wc -l < "${stdcell_names}" | tr -d '[:space:]')
  if [ "${count}" -eq 0 ]; then
    echo "WARNING: no LEF MACRO names found under ${run}/ref; no standard-cell DRC cell list generated" >&2
    return
  fi

  {
    echo "N28 block DRC standard-cell reference cells"
    echo "Design: ${design}"
    echo "Source LEF count: ${#lef_files[@]}"
    echo "Cell count: ${count}"
    echo
    sed -n '1,200p' "${stdcell_names}"
    if [ "${count}" -gt 200 ]; then
      echo "... truncated in report; full list: ${stdcell_names}"
    fi
  } > "${stdcell_report}"
}

enable_drc_cell_names() {
  local runset=$1

  if [ "${mode}" != "block" ]; then
    return
  fi

  perl -0pi -e 's|^//DRC CELL NAME YES CELL SPACE XFORM ALL|DRC CELL NAME YES CELL SPACE XFORM ALL|m' "${runset}"
  if ! grep -q '^DRC CELL NAME YES CELL SPACE XFORM ALL' "${runset}"; then
    echo 'DRC CELL NAME YES CELL SPACE XFORM ALL' >> "${runset}"
  fi
}

emit_runset() {
  local name=$1
  local deck=$2
  local result_db=$3
  local summary=$4
  local layout_gds=${5:-${gds}}
  local primary=${6:-${design}}
  local runset=${out}/${name}.runset

  sed \
    -e "s|^LAYOUT PATH .*|LAYOUT PATH \"${layout_gds}\"|" \
    -e "s|^LAYOUT PRIMARY .*|LAYOUT PRIMARY \"${primary}\"|" \
    -e "s|^DRC RESULTS DATABASE .*|DRC RESULTS DATABASE \"${result_db}\" ASCII|" \
    -e "s|^DRC SUMMARY REPORT .*|DRC SUMMARY REPORT \"${summary}\"|" \
    "${deck}" > "${runset}"

  case "${mode}" in
    block)
      perl -0pi -e 's/^#DEFINE (FULL_CHIP|WITH_SEALRING|WITH_APRDL|WITH_POLYIMIDE|AP_28K_THICKNESS)\b/\/\/#DEFINE $1/mg' "${runset}"
      ;;
    fullchip)
      ;;
  esac

  case "${name}" in
    drc|drc_filled)
      enable_drc_cell_names "${runset}"
      ;;
  esac
}

die_bounds_um() {
  local die_line
  die_line=$(zcat -f "${def}" 2>/dev/null | awk '/^DIEAREA[[:space:]]/ {print; exit}')
  if [ -z "${die_line}" ]; then
    echo "ERROR: cannot find DIEAREA in ${def}" >&2
    exit 1
  fi
  awk '
    {
      n = 0
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^-?[0-9]+$/) {
          n++
          if (n % 2 == 1) {
            x = $i + 0
            if (n == 1 || x < minx) minx = x
            if (n == 1 || x > maxx) maxx = x
          } else {
            y = $i + 0
            if (n == 2 || y < miny) miny = y
            if (n == 2 || y > maxy) maxy = y
          }
        }
      }
      if (n < 4) exit 2
      printf "%.3f %.3f %.3f %.3f\n", minx / 1000.0, miny / 1000.0, maxx / 1000.0, maxy / 1000.0
    }' <<< "${die_line}" || {
      echo "ERROR: failed to parse DIEAREA from ${def}: ${die_line}" >&2
      exit 1
    }
}

emit_dummy_runset() {
  if [ "${enable_dummy}" != "1" ]; then
    return
  fi
  for f in "${dummy_od_po_tgz}" "${dummy_metal_via_tgz}" "${def}"; do
    if [ ! -s "${f}" ]; then
      echo "ERROR: ENABLE_CALIBRE_DUMMY_FILL=1 but required file is missing: ${f}" >&2
      exit 1
    fi
  done

  local dummy_dir=${out}/dummy_util
  local dummy_deck=${out}/dummy_fill.combined.svrf
  local runset=${out}/dummy_fill.runset
  local xlb ylb xrt yrt
  mkdir -p "${dummy_dir}"
  tar xzf "${dummy_od_po_tgz}" -C "${dummy_dir}"
  tar xzf "${dummy_metal_via_tgz}" -C "${dummy_dir}"
  cat \
    "${dummy_dir}/Dummy_OD_PO_Calibre_28nm_HP.13a" \
    "${dummy_dir}/Dummy_Metal_Via_Calibre_28nm.13a" \
    > "${dummy_deck}"

  read -r xlb ylb xrt yrt <<< "$(die_bounds_um)"
  sed \
    -e "s|^LAYOUT PATH .*|LAYOUT PATH \"${gds}\"|" \
    -e "s|^LAYOUT PRIMARY .*|LAYOUT PRIMARY \"${design}\"|" \
    -e "0,/^DRC RESULTS DATABASE /s|^DRC RESULTS DATABASE .*|DRC RESULTS DATABASE \"${dummy_raw_gds}\" GDSII|" \
    -e "0,/^DRC SUMMARY REPORT /s|^DRC SUMMARY REPORT .*|DRC SUMMARY REPORT \"${reports}/${design}.dummy_fill.summary\"|" \
    "${dummy_deck}" > "${runset}"

  XLB="${xlb}" YLB="${ylb}" XRT="${xrt}" YRT="${yrt}" ENABLE_TCD="${enable_tcd}" perl -0pi -e '
    s|//#DEFINE ChipWindowUsed|#DEFINE ChipWindowUsed|;
    s|//#DEFINE dmOnCorner|#DEFINE dmOnCorner|;
    s|//#DEFINE COMBINE_DODPO_DMVIA|#DEFINE COMBINE_DODPO_DMVIA|;
    if ($ENV{ENABLE_TCD} eq "1") {
      s|^//#DEFINE FILL_TCD_PATTERN|#DEFINE FILL_TCD_PATTERN|m;
    } else {
      s|^#DEFINE FILL_TCD_PATTERN|//#DEFINE FILL_TCD_PATTERN|m;
    }
    s|^VARIABLE xLB\s+[-0-9.]+|VARIABLE xLB   $ENV{XLB}|m;
    s|^VARIABLE yLB\s+[-0-9.]+|VARIABLE yLB   $ENV{YLB}|m;
    s|^VARIABLE xRT\s+[-0-9.]+|VARIABLE xRT   $ENV{XRT}|m;
    s|^VARIABLE yRT\s+[-0-9.]+|VARIABLE yRT   $ENV{YRT}|m;
    s|//#DEFINE 2K_THICK_M6|#DEFINE 2K_THICK_M6|;
    s|//#DEFINE 2K_THICK_M7|#DEFINE 2K_THICK_M7|;
    s|//#DEFINE 12K_THICK_M8|#DEFINE 12K_THICK_M8|;
  ' "${runset}"
}

emit_stdcell_cell_file

emit_runset \
  drc \
  "${drc_in}" \
  "${results}/${design}.drc.results" \
  "${reports}/${design}.drc.summary"

emit_dummy_runset

emit_runset \
  drc_filled \
  "${drc_in}" \
  "${results}/${design}.drc.results" \
  "${reports}/${design}.drc.summary" \
  "${dummy_gds}" \
  "${dummy_top}"

emit_runset \
  antenna \
  "${ant_in}" \
  "${results}/${design}.ant.results" \
  "${reports}/${design}.ant.summary"

emit_runset \
  mim_antenna \
  "${mim_ant_in}" \
  "${results}/${design}.mim_ant.results" \
  "${reports}/${design}.mim_ant.summary"

for runset in "${out}/drc.runset" "${out}/drc_filled.runset" "${out}/antenna.runset" "${out}/mim_antenna.runset"; do
  grep -q "^LAYOUT PATH \"${gds}\"" "${runset}" || {
    if [ "${runset}" != "${out}/drc_filled.runset" ] || ! grep -q "^LAYOUT PATH \"${dummy_gds}\"" "${runset}"; then
      echo "ERROR: failed to rewrite LAYOUT PATH in ${runset}" >&2
      exit 1
    fi
  }
  grep -q "^LAYOUT PRIMARY \"${design}\"" "${runset}" || {
    if [ "${runset}" != "${out}/drc_filled.runset" ] || ! grep -q "^LAYOUT PRIMARY \"${dummy_top}\"" "${runset}"; then
      echo "ERROR: failed to rewrite LAYOUT PRIMARY in ${runset}" >&2
      exit 1
    fi
  }
  grep -q '^DRC RESULTS DATABASE "' "${runset}" || {
    echo "ERROR: failed to rewrite DRC RESULTS DATABASE in ${runset}" >&2
    exit 1
  }
  grep -q '^DRC SUMMARY REPORT "' "${runset}" || {
    echo "ERROR: failed to rewrite DRC SUMMARY REPORT in ${runset}" >&2
    exit 1
  }
done

if [ "${enable_dummy}" = "1" ]; then
  grep -q "^LAYOUT PATH \"${gds}\"" "${out}/dummy_fill.runset" || {
    echo "ERROR: failed to rewrite LAYOUT PATH in ${out}/dummy_fill.runset" >&2
    exit 1
  }
  grep -q "^DRC RESULTS DATABASE \"${dummy_raw_gds}\" GDSII" "${out}/dummy_fill.runset" || {
    echo "ERROR: failed to rewrite dummy DRC RESULTS DATABASE in ${out}/dummy_fill.runset" >&2
    exit 1
  }
  grep -q "^LAYOUT PATH \"${dummy_gds}\"" "${out}/drc_filled.runset" || {
    echo "ERROR: failed to set filled DRC LAYOUT PATH to merged dummy GDS" >&2
    exit 1
  }
  grep -q "^LAYOUT PRIMARY \"${dummy_top}\"" "${out}/drc_filled.runset" || {
    echo "ERROR: failed to set filled DRC LAYOUT PRIMARY to ${dummy_top}" >&2
    exit 1
  }
  if grep -q "^DRC RESULTS DATABASE \"${dummy_gds}\" GDSII" "${out}/dummy_fill.runset"; then
    echo "ERROR: failed to rewrite dummy DRC RESULTS DATABASE in ${out}/dummy_fill.runset" >&2
    exit 1
  fi
fi

if [ "${mode}" = "block" ] && grep -Eq '^#DEFINE (FULL_CHIP|WITH_SEALRING|WITH_APRDL|WITH_POLYIMIDE|AP_28K_THICKNESS)\b' "${out}/drc.runset" "${out}/antenna.runset" "${out}/mim_antenna.runset"; then
  echo "ERROR: block mode left a full-chip/package define enabled" >&2
  exit 1
fi

if [ "${mode}" = "block" ]; then
  for runset in "${out}/drc.runset" "${out}/drc_filled.runset"; do
    grep -q '^DRC CELL NAME YES CELL SPACE XFORM ALL' "${runset}" || {
      echo "ERROR: failed to enable DRC cell names in ${runset}" >&2
      exit 1
    }
  done
fi

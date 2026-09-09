#!/usr/bin/env bash
set -euo pipefail

gds_rel=${1:?usage: gds_clean.sh <gds-path-relative-to-root-or-absolute>}
root=${ROOT_PATH:?ROOT_PATH is required}
calibredrv_tool=${CALIBREDRV_TOOL:-calibredrv}
top_text_mag=${GDS_TOP_TEXT_MAG:-0.2}
top_text_edge_offset=${GDS_TOP_TEXT_EDGE_OFFSET:-500}

if [[ "${gds_rel}" = /* ]]; then
  gds=${gds_rel}
else
  gds=${root}/${gds_rel}
fi

if [ ! -s "${gds}" ]; then
  echo "ERROR: missing or empty GDS: ${gds}" >&2
  exit 1
fi
if [ ! -x "${calibredrv_tool}" ]; then
  echo "ERROR: calibredrv not executable: ${calibredrv_tool}" >&2
  exit 1
fi

work_dir=$(dirname "${gds}")
base=$(basename "${gds}" .gds)
tmp_gds=${work_dir}/${base}.noproperties.gds
strip_tcl=${work_dir}/${base}.strip_properties.tcl

rm -f "${tmp_gds}" "${strip_tcl}"
{
  printf 'set in_gds {%s}\n' "${gds}"
  printf 'set out_gds {%s}\n' "${tmp_gds}"
  printf 'set L [layout create $in_gds -dt_expand -preservePaths -preserveTextAttributes -noReport]\n'
  printf 'set topcell [$L topcell]\n'
  printf 'set top_text_mag {%s}\n' "${top_text_mag}"
  printf 'set top_text_edge_offset {%s}\n' "${top_text_edge_offset}"
  printf 'proc delete_text_tuple {L cell lay t} {\n'
  printf '  if {[llength $t] >= 7} {\n'
  printf '    $L delete text $cell $lay [lindex $t 1] [lindex $t 2] [lindex $t 0] [lindex $t 3] [lindex $t 4] [lindex $t 5] [lindex $t 6]\n'
  printf '  } elseif {[llength $t] >= 4} {\n'
  printf '    $L delete text $cell $lay [lindex $t 1] [lindex $t 2] [lindex $t 0] [lindex $t 3]\n'
  printf '  } else {\n'
  printf '    $L delete text $cell $lay [lindex $t 1] [lindex $t 2] [lindex $t 0]\n'
  printf '  }\n'
  printf '}\n'
  printf 'proc nearest_edge {x y minx maxx miny maxy} {\n'
  printf '  set best_edge bottom\n'
  printf '  set best_dist [expr {abs($y - $miny)}]\n'
  printf '  foreach {edge dist} [list top [expr {abs($maxy - $y)}] left [expr {abs($x - $minx)}] right [expr {abs($maxx - $x)}]] {\n'
  printf '    if {$dist < $best_dist} {\n'
  printf '      set best_edge $edge\n'
  printf '      set best_dist $dist\n'
  printf '    }\n'
  printf '  }\n'
  printf '  return $best_edge\n'
  printf '}\n'
  printf 'set top_text_records {}\n'
  printf 'set minx ""; set maxx ""; set miny ""; set maxy ""\n'
  printf 'foreach lay [$L layers -cell $topcell] {\n'
  printf '  foreach t [$L iterator text $topcell $lay range 0 end] {\n'
  printf '    set x [lindex $t 1]\n'
  printf '    set y [lindex $t 2]\n'
  printf '    lappend top_text_records [list $lay $t]\n'
  printf '    if {$minx eq "" || $x < $minx} { set minx $x }\n'
  printf '    if {$maxx eq "" || $x > $maxx} { set maxx $x }\n'
  printf '    if {$miny eq "" || $y < $miny} { set miny $y }\n'
  printf '    if {$maxy eq "" || $y > $maxy} { set maxy $y }\n'
  printf '  }\n'
  printf '}\n'
  printf 'array set edge_counts {top 0 bottom 0 left 0 right 0}\n'
  printf 'set normalized_top_texts 0\n'
  printf 'foreach rec $top_text_records {\n'
  printf '    set lay [lindex $rec 0]\n'
  printf '    set t [lindex $rec 1]\n'
  printf '    set label [lindex $t 0]\n'
  printf '    set x [lindex $t 1]\n'
  printf '    set y [lindex $t 2]\n'
  printf '    set presentation 0\n'
  printf '    set strans 0\n'
  printf '    set angle 0.0\n'
  printf '    if {[llength $t] >= 4} { set presentation [lindex $t 3] }\n'
  printf '    if {[llength $t] >= 7} {\n'
  printf '      set strans [lindex $t 4]\n'
  printf '      set angle [lindex $t 6]\n'
  printf '    }\n'
  printf '    set edge [nearest_edge $x $y $minx $maxx $miny $maxy]\n'
  printf '    if {$edge eq "bottom"} {\n'
  printf '      set y [expr {$miny - $top_text_edge_offset}]\n'
  printf '      set angle 90.0\n'
  printf '    } elseif {$edge eq "top"} {\n'
  printf '      set y [expr {$maxy + $top_text_edge_offset}]\n'
  printf '      set angle 270.0\n'
  printf '    } else {\n'
  printf '      # Left/right edge labels keep their original location and orientation.\n'
  printf '    }\n'
  printf '    delete_text_tuple $L $topcell $lay $t\n'
  printf '    $L create text $topcell $lay $x $y $label $presentation $strans $top_text_mag $angle\n'
  printf '    incr edge_counts($edge)\n'
  printf '    incr normalized_top_texts\n'
  printf '}\n'
  printf 'set removed_texts 0\n'
  printf 'foreach cell [$L cells] {\n'
  printf '  if {$cell eq $topcell} { continue }\n'
  printf '  foreach lay [$L layers -cell $cell] {\n'
  printf '    set texts [$L iterator text $cell $lay range 0 end]\n'
  printf '    foreach t $texts {\n'
  printf '      delete_text_tuple $L $cell $lay $t\n'
  printf '      incr removed_texts\n'
  printf '    }\n'
  printf '  }\n'
  printf '}\n'
  printf 'puts "Normalized top-cell text objects: $normalized_top_texts (mag=$top_text_mag, edge_offset=$top_text_edge_offset)"\n'
  printf 'puts "Top-cell text edge counts: top=$edge_counts(top) bottom=$edge_counts(bottom) left=$edge_counts(left) right=$edge_counts(right)"\n'
  printf 'puts "Removed non-top-cell text objects: $removed_texts"\n'
  printf '$L gdsout $out_gds\n'
} > "${strip_tcl}"

MGC_TMPDIR=/tmp "${calibredrv_tool}" -64 "${strip_tcl}"
if [ ! -s "${tmp_gds}" ]; then
  echo "ERROR: CalibreDRV did not create property-stripped GDS: ${tmp_gds}" >&2
  exit 1
fi

mv -f "${tmp_gds}" "${gds}"
rm -f "${strip_tcl}"
echo "Stripped GDS properties: ${gds}"

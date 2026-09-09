#!/usr/bin/env bash
set -euo pipefail

lc_tool=${1:?LC executable required}
design_path="${RUN_PATH:?}/${DESIGN_NAME:?}"
db="$design_path/results/$DESIGN_NAME.db"
log="$design_path/logs/run_lc.log"
write_log="$design_path/logs/run_lc.write.log"
marker=LC_WRITE_DB_COMPLETE

rm -f -- "$db" "$log" "$write_log"
lc_status=0
"$lc_tool" -f "$ROOT_PATH/scripts/pt/library_compile.tcl" > "$log" 2>&1 || lc_status=$?
cat "$log"

if [[ "$lc_status" != 0 && "$lc_status" != 139 ]]; then
    exit "$lc_status"
fi
if [[ ! -s "$db" ]] || ! grep -Fxq "$marker" "$log"; then
    echo "ERROR: LC did not confirm completion of a new nonempty DB." >&2
    exit 1
fi

if [[ "$lc_status" == 139 ]]; then
    sed '/^LC_WRITE_DB_COMPLETE$/q' "$log" > "$write_log"
else
    cp "$log" "$write_log"
fi
python3 "$ROOT_PATH/scripts/utilities/log_review.py" "$write_log" "$design_path/logs"

if [[ "$lc_status" == 139 ]]; then
    echo "WARNING: LC wrote the DB but crashed during exit (139); accepting the completed write. Full log: $log" >&2
fi

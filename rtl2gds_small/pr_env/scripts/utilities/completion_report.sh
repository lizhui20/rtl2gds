#!/usr/bin/env bash
set -euo pipefail

label=${1:?usage: completion_report.sh <label>}
design=${DESIGN_NAME:?DESIGN_NAME is required}

case "${label}" in
  pnr)
    echo "PnR flow complete for ${design}"
    ;;
  pnr_eco)
    echo "PnR ECO flow complete for ${design}"
    ;;
  signoff)
    echo "Signoff flow complete for ${design}"
    ;;
  *)
    echo "ERROR: unsupported flow label: ${label}" >&2
    exit 1
    ;;
esac

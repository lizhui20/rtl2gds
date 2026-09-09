#!/usr/bin/env bash
set -euo pipefail

kind=${1:?usage: verification_config.sh drc|lvs}
design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}

source "${root}/scripts/utilities/config_load.sh"
pdk_profile=${PDK_PROFILE:-}

mkdir -p \
  "${root}/${design}/work/signoff/calibre" \
  "${root}/${design}/results/signoff" \
  "${root}/${design}/reports/signoff"

case "${kind}:${pdk_profile}" in
  drc:tsmc28hpcplus)
    DESIGN_NAME="${design}" ROOT_PATH="${root}" bash "${root}/scripts/utilities/drc_rules.sh"
    ;;
  lvs:tsmc28hpcplus)
    DESIGN_NAME="${design}" ROOT_PATH="${root}" bash "${root}/scripts/utilities/lvs_rules.sh"
    ;;
  drc:*|lvs:*)
    echo "ERROR: unsupported PDK_PROFILE for Calibre runsets: ${pdk_profile}; expected tsmc28hpcplus" >&2
    exit 1
    ;;
  *)
    echo "ERROR: unknown Calibre runset kind '${kind}'" >&2
    exit 1
    ;;
esac

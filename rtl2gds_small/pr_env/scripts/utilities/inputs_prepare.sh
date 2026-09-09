#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
run=${root}/${design}

mkdir -p "${run}/logs"
date '+%Y-%m-%d %H:%M:%S' > "${run}/logs/run_prepare_inputs.done"

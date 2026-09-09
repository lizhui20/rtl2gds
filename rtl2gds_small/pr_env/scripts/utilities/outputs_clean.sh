#!/usr/bin/env bash
set -euo pipefail

design=${DESIGN_NAME:?DESIGN_NAME is required}
root=${ROOT_PATH:?ROOT_PATH is required}
run=${root}/${design}

rm -rf "${run}/work/"* "${run}/logs/"* "${run}/reports/"*
rm -rf "${run}/results/${design}_pnr.ndm"
rm -rf "${root}/"*command.log "${root}/"*.svf "${root}/fc_command.log"

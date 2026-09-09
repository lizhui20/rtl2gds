#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_PATH:?ROOT_PATH is required}
signoff=${SIGNOFF:-${root}/scripts/signoff}

bash "${signoff}/extraction_inputs.sh"
bash "${signoff}/extraction_model.sh"

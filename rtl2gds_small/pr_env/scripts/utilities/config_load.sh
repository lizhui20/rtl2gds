#!/usr/bin/env bash

flow_config_tcl_scalar() {
  local file=$1
  local name=$2

  [ -f "${file}" ] || return 1
  sed -n -E "s/^[[:space:]]*set[[:space:]]+${name}[[:space:]]+\"?([^\"#[:space:]]+)\"?.*$/\1/p" "${file}" | tail -n 1
}

flow_config_apply_scalar() {
  local name=$1
  local default_value=${2:-}
  local value=

  if [ -n "${!name:-}" ]; then
    return
  fi

  if [ -n "${FLOW_DESIGN_SETUP:-}" ]; then
    value=$(flow_config_tcl_scalar "${FLOW_DESIGN_SETUP}" "${name}" || true)
  fi
  if [ -z "${value}" ]; then
    value=$(flow_config_tcl_scalar "${FLOW_USER_SETUP}" "${name}" || true)
  fi
  if [ -z "${value}" ]; then
    value=${default_value}
  fi

  if [ -n "${value}" ]; then
    export "${name}=${value}"
  fi
}

flow_config_load() {
  ROOT_PATH=${ROOT_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
  DESIGN_NAME=${DESIGN_NAME:-}
  UTIL=${UTIL:-${ROOT_PATH}/scripts/utilities}
  PNR=${PNR:-${ROOT_PATH}/scripts/pnr}
  SIGNOFF=${SIGNOFF:-${ROOT_PATH}/scripts/signoff}

  FLOW_USER_SETUP=${FLOW_USER_SETUP:-${ROOT_PATH}/scripts/utilities/layout_defaults.tcl}
  FLOW_CURRENT_PDK=${FLOW_CURRENT_PDK:-${ROOT_PATH}/scripts/pdk/process_select.tcl}
  if [ -n "${DESIGN_NAME}" ]; then
    FLOW_DESIGN_SETUP=${FLOW_DESIGN_SETUP:-${ROOT_PATH}/${DESIGN_NAME}/inputs/${DESIGN_NAME}.pr_user_setting.tcl}
  else
    FLOW_DESIGN_SETUP=${FLOW_DESIGN_SETUP:-}
  fi

  if [ -z "${PDK_PROFILE:-}" ]; then
    PDK_PROFILE=$(flow_config_tcl_scalar "${FLOW_CURRENT_PDK}" PDK_PROFILE || true)
    export PDK_PROFILE
  fi

  flow_config_apply_scalar ENABLE_IO_LIBRARY 0
  flow_config_apply_scalar ENABLE_CALIBRE_DUMMY_FILL 1
  flow_config_apply_scalar ENABLE_CALIBRE_TCD_FILL 0
  flow_config_apply_scalar N28_DRC_MODE block
  flow_config_apply_scalar CALIBRE_LVS_SOURCE_NETLIST logical

  export ROOT_PATH DESIGN_NAME UTIL PNR SIGNOFF
}

flow_config_load

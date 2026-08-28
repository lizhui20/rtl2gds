#!/usr/bin/env bash

set -u

output=${1:-environment-report.txt}

commands=(
  virtuoso spectre xrun irun innovus genus
  liberate
  vcs verdi dc_shell fc_shell fm_shell lc_shell pt_shell
  dft_shell sg_shell spyglass vc_static_shell StarXtract hspice
  calibre vsim
  ngspice iverilog verilator yosys openroad klayout magic
)

{
  printf '# IC design VM environment report\n'
  printf 'generated_at_utc: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '\n## Operating system\n'
  if [[ -r /etc/redhat-release ]]; then
    cat /etc/redhat-release
  fi
  if [[ -r /etc/os-release ]]; then
    sed -n -E '/^(NAME|VERSION|VERSION_ID|PLATFORM_ID)=/p' /etc/os-release
  fi
  uname -srmo

  printf '\n## Virtual hardware\n'
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    printf 'virtualization: '
    systemd-detect-virt || true
  fi
  if [[ -r /sys/class/dmi/id/product_name ]]; then
    printf 'product_name: '
    cat /sys/class/dmi/id/product_name
  fi
  lscpu | sed -n -E '/^(Architecture|CPU\(s\)|Model name|Thread|Core|Socket|Virtualization):/p'
  free -h
  df -hT -x tmpfs -x devtmpfs

  printf '\n## Detected EDA product release directories\n'
  {
    find /opt/cadence -mindepth 1 -maxdepth 1 -type d ! -name 'lic*' -print 2>/dev/null
    find /opt/synopsys -mindepth 2 -maxdepth 2 -type d \
      ! -path '/opt/synopsys/SynopsysInstaller_*/*' -print 2>/dev/null
    find /opt/mentor -mindepth 2 -maxdepth 2 -type d \
      ! -path '/opt/mentor/_msidata/*' -print 2>/dev/null
  } | LC_ALL=C sort

  printf '\n## EDA commands found in PATH\n'
  for command_name in "${commands[@]}"; do
    if command_path=$(command -v "$command_name" 2>/dev/null); then
      printf '%-16s %s\n' "$command_name" "$command_path"
    fi
  done
  if bash -lic 'alias lmg >/dev/null 2>&1' >/dev/null 2>&1; then
    printf '%-16s %s\n' lmg '<interactive shell alias; expansion redacted>'
  fi

  printf '\n## Installed packages with common EDA names\n'
  if command -v rpm >/dev/null 2>&1; then
    rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}\n' 2>/dev/null \
      | LC_ALL=C sort \
      | grep -Ei '(^|[-_])(ngspice|iverilog|verilator|yosys|openroad|klayout|magic)([-_]|$)' \
      || true
  fi

  printf '\n## Review notice\n'
  printf '%s\n' 'Manually inspect this report before publishing it.'
  printf '%s\n' 'Remove usernames, hostnames, private paths, network details, tokens, and keys.'
} >"$output"

printf 'Wrote %s\n' "$output"

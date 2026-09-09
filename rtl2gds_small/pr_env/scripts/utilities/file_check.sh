#!/usr/bin/env bash
set -euo pipefail

file=${1:?usage: file_check.sh <file>}
test -s "${file}"

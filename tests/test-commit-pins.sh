#!/usr/bin/env bash
set -euo pipefail

fail=0

check_pin() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "ERROR: Missing ${file}"
    fail=1
    return
  fi
  local sha
  sha=$(tr -d '\n\r' < "${file}")
  if [[ "${#sha}" -ne 40 || ! "${sha}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "ERROR: ${file} must contain a 40-char lowercase hex SHA (got: '${sha}')"
    fail=1
  else
    echo "OK: ${file} -> ${sha}"
  fi
}

check_pin "mcpelauncher.commit"
check_pin "mcpelauncher-ui.commit"
# msa is optional for default builds, but validate if present
if [[ -f "msa.commit" ]]; then
  check_pin "msa.commit"
else
  echo "INFO: msa.commit not present (MSA disabled path)"
fi

exit "${fail}"
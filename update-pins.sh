#!/usr/bin/env bash
set -euo pipefail

# Updates commit pin files to latest upstream commit hashes.
# Requires git and network access.

# Repos
REPO_MCPELAUNCHER="https://github.com/minecraft-linux/mcpelauncher-manifest.git"
REPO_UI="https://github.com/minecraft-linux/mcpelauncher-ui-manifest.git"
REPO_MSA="https://github.com/minecraft-linux/msa-manifest.git"

fetch_head() {
  local repo="$1"
  git ls-remote "$repo" HEAD | awk '{print $1}'
}

update_pin() {
  local file="$1"
  local sha="$2"
  if [[ -z "${sha}" || "${#sha}" -ne 40 ]]; then
    echo "Failed to resolve SHA for ${file}" >&2
    exit 1
  fi
  echo "${sha}" > "${file}"
  echo "Updated ${file} -> ${sha}"
}

main() {
  local m_sha ui_sha msa_sha
  echo "Resolving latest upstream commits..."
  m_sha=$(fetch_head "${REPO_MCPELAUNCHER}")
  ui_sha=$(fetch_head "${REPO_UI}")
  msa_sha=$(fetch_head "${REPO_MSA}")

  update_pin mcpelauncher.commit "${m_sha}"
  update_pin mcpelauncher-ui.commit "${ui_sha}"
  update_pin msa.commit "${msa_sha}"

  echo "Done. Review diffs and rebuild."
}

main "$@"
#!/usr/bin/env bash
# Test for new validation and compatibility tools

set -euo pipefail

fail=0

echo "Testing new validation and compatibility tools..."

# Test that scripts exist and are executable
test_executable() {
  local script="$1"
  if [[ ! -f "$script" ]]; then
    echo "ERROR: $script not found"
    fail=1
    return
  fi
  if [[ ! -x "$script" ]]; then
    echo "ERROR: $script not executable"
    fail=1
    return
  fi
  echo "OK: $script exists and is executable"
}

# Test that scripts show help correctly
test_help() {
  local script="$1"
  local help_arg="${2:---help}"
  
  if ! timeout 10s "$script" "$help_arg" >/dev/null 2>&1; then
    echo "ERROR: $script help command failed"
    fail=1
    return
  fi
  echo "OK: $script help works"
}

# Test executable status
test_executable "./build_gles30_validator.sh"
test_executable "./ensure-appimage-compatibility.sh"

# Test help commands
test_help "./build_gles30_validator.sh" "help"
test_help "./ensure-appimage-compatibility.sh" "--help"

# Test quirks-qt6.sh syntax
if ! bash -n quirks-qt6.sh; then
  echo "ERROR: quirks-qt6.sh has syntax errors"
  fail=1
else
  echo "OK: quirks-qt6.sh syntax check passed"
fi

# Test COMPATIBILITY.md exists
if [[ ! -f "COMPATIBILITY.md" ]]; then
  echo "ERROR: COMPATIBILITY.md not found"
  fail=1
else
  echo "OK: COMPATIBILITY.md exists"
fi

if [[ $fail -eq 0 ]]; then
  echo "All new tool tests passed!"
else
  echo "Some tool tests failed!"
fi

exit $fail
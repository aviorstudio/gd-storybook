#!/usr/bin/env bash
set -euo pipefail

root=${1:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
readme="$root/README.md"
assertions=0

require_text() {
  local expected=$1
  if ! grep -Fq -- "$expected" "$readme"; then
    printf 'missing required placeholder statement: %s\n' "$expected" >&2
    return 1
  fi
  assertions=$((assertions + 1))
}

test -f "$readme"
require_text '**Status: placeholder — retained, not implemented.**'
require_text 'contains no Godot addon, API, package, or distributable artifact'
require_text 'There are no releases or implementation/support claims'
require_text 'requires a separate approved product contract'

for unexpected in addon addons project.godot plugin.cfg; do
  if test -e "$root/$unexpected"; then
    printf 'placeholder unexpectedly contains implementation path: %s\n' "$unexpected" >&2
    exit 1
  fi
  assertions=$((assertions + 1))
done

printf 'PLACEHOLDER_ASSERTIONS_REACHED=%d\n' "$assertions"

if test "${2:-}" = --self-test; then
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  cp "$readme" "$fixture/README.md"
  perl -0pi -e 's/\*\*Status: placeholder — retained, not implemented\.\*\*/Status removed/' "$fixture/README.md"
  if bash "$0" "$fixture" >/dev/null 2>&1; then
    printf 'negative control unexpectedly passed\n' >&2
    exit 1
  fi
  printf 'NEGATIVE_CONTROL_FAILED_AS_EXPECTED=1\n'
  cp "$readme" "$fixture/README.md"
  bash "$0" "$fixture"
  printf 'RESTORED_CONTROL_PASSED=1\n'
fi

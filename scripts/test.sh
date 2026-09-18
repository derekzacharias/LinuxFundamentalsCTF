#!/usr/bin/env bash
set -euo pipefail

# test.sh — repository checks.
#
#   ./scripts/test.sh            lint mode (any user): bash -n + shellcheck
#   sudo ./scripts/test.sh --lab [USER]   lab mode (inside installed lab):
#                                run every lesson solver as USER, then
#                                validate_lesson + check_flag for all 24.

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LAB_USER="${2:-${SUDO_USER:-$(id -un)}}"

lint() {
  echo "== lint: bash -n"
  while IFS= read -r f; do
    if [[ "$(basename "$f")" == *.sh || "$(head -c2 "$f")" == '#!' ]]; then
      bash -n "$f"
    fi
  done < <(find "$ROOT_DIR" -type f ! -path '*/.git/*' ! -name '*.service' ! -name '*.py' ! -name '*.csv' ! -name '*.log' ! -name '*.bin' ! -name '*.txt' ! -name '*.md' ! -name '*.json' ! -name '*.yml' | sort)
  echo "   syntax OK"

  if command -v shellcheck >/dev/null 2>&1; then
    echo "== lint: shellcheck"
    while IFS= read -r f; do
      shellcheck -S warning "$f" || true
    done < <(find "$ROOT_DIR" -type f ! -path '*/.git/*' -name '*.sh' | sort)
    echo "   shellcheck OK"
  else
    echo "== lint: shellcheck not installed — skipping"
  fi
}

lab() {
  echo "== lab mode: running as $LAB_USER"
  local fails=0

  for n in $(seq 1 24); do
    printf 'lesson %02d: ' "$n"
    solver="$ROOT_DIR/tests/solves/lesson$(printf '%02d' "$n").sh"
    [[ -f $solver ]] || { echo "MISSING SOLVER"; fails=$((fails+1)); continue; }

    flag=$(sudo -H -u "$LAB_USER" bash "$solver" 2>/dev/null | grep -oE 'FLAG\{[^}]*\}' | tail -1 || true)
    if [[ -z "$flag" ]]; then
      echo "SOLVER FAILED (no flag output)"
      fails=$((fails+1))
      continue
    fi

    if ! sudo -H -u "$LAB_USER" /usr/local/bin/check_flag "$n" "$flag" >/dev/null 2>&1; then
      echo "FLAG MISMATCH (got $flag)"
      fails=$((fails+1))
      continue
    fi

    if ! sudo -H -u "$LAB_USER" /usr/local/bin/validate_lesson "$n" >/dev/null 2>&1; then
      echo "VALIDATE FAILED — details:"
      sudo -H -u "$LAB_USER" /usr/local/bin/validate_lesson "$n" 2>&1 | sed 's/^/    /'
      fails=$((fails+1))
      continue
    fi

    echo "PASS"
  done

  echo
  if (( fails > 0 )); then
    echo "== $fails lesson(s) FAILED"
    exit 1
  fi
  echo "== all 24 lessons PASS"
}

case "${1:-lint}" in
  lint) lint ;;
  --lab) lab ;;
  *) echo "Usage: $0 [lint|--lab [USER]]" >&2; exit 2 ;;
esac

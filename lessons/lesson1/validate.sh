#!/usr/bin/env bash
set -euo pipefail

# Validation for Lesson 1: checks the presence and exact value of the flag file.
FLAG_PATH="/opt/flags/lesson1.flag"
EXPECTED='FLAG{lesson_01_welcome_to_linux}'

if [[ ! -f "$FLAG_PATH" ]]; then
  echo "ERROR: Flag file not found at $FLAG_PATH" >&2
  exit 1
fi

if grep -qx "$EXPECTED" "$FLAG_PATH"; then
  echo "OK: Lesson 1 flag present and correct"
  exit 0
else
  echo "ERROR: Flag content mismatch" >&2
  exit 2
fi

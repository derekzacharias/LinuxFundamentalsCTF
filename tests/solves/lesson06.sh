#!/usr/bin/env bash
set -euo pipefail
# Wait for the logger to write the flag (every ~10s)
for _ in $(seq 1 20); do
  if grep -q 'FLAG{lesson_06' /var/log/lesson6.log 2>/dev/null; then
    grep 'FLAG{lesson_06' /var/log/lesson6.log | head -1
    exit 0
  fi
  sleep 3
done
echo "timed out waiting for lesson6 flag" >&2
exit 1

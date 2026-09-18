#!/usr/bin/env bash
# Lesson 6: background logger. Writes a heartbeat every 2s and the flag every 5th loop.
set -euo pipefail
LOG="/var/log/lesson6.log"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"
i=0
while true; do
  i=$((i+1))
  if (( i % 5 == 0 )); then
    echo "$(date -Is) lesson6: FLAG{lesson_06_ps_master}" >> "$LOG"
  else
    echo "$(date -Is) lesson6: heartbeat" >> "$LOG"
  fi
  sleep 2
done

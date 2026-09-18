#!/usr/bin/env bash
# Lesson 16: signal worker. Copies to ~/lesson16_worker.sh, run in background,
# then send SIGUSR1 to make it write the flag.
set -euo pipefail
OUT="$HOME/lesson16_flag.txt"
on_usr1() {
  echo "FLAG{lesson_16_signal_sergeant}" > "$OUT"
  exit 0
}
trap on_usr1 USR1
echo "$$ ready: waiting for SIGUSR1 (kill -USR1 $$)" 
while true; do sleep 1; done

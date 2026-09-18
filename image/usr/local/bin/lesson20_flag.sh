#!/usr/bin/env bash
# Lesson 20: prints the flag to stdout every 10s; systemd captures it in the journal.
# The service stays active so learners can practice systemctl status/start/enable.
set -euo pipefail
while true; do
  echo "$(date -Is) lesson20: FLAG{lesson_20_systemd_savvy}"
  sleep 10
done

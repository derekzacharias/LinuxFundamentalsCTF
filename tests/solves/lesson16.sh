#!/usr/bin/env bash
set -euo pipefail
cp /opt/challenges/lesson16/worker.sh ~/lesson16_worker.sh
chmod +x ~/lesson16_worker.sh
~/lesson16_worker.sh &
pid=$!
sleep 1
kill -USR1 "$pid"
for _ in $(seq 1 10); do
  [[ -f ~/lesson16_flag.txt ]] && break
  sleep 1
done
cat ~/lesson16_flag.txt

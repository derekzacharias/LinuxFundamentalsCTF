#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/lesson17
awk -F, 'NR>1 {print $3}' /opt/data/lesson17/payload.csv | paste -sd '' > ~/lesson17/flag.txt
cat ~/lesson17/flag.txt

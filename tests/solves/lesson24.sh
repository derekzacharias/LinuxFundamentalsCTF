#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/lesson24
base64 -d /opt/challenges/lesson24/stage1 > ~/lesson24/stage2.tar.gz
tar -xzf ~/lesson24/stage2.tar.gz -C ~/lesson24
next=$(grep -R 'next stage' ~/lesson24/breach_logs | sed 's/.*next stage: //')
cat "$(readlink -f "$next")"
sudo chmod 644 /opt/challenges/lesson24/pieces.csv
awk -F, 'NR>1 {print $4}' /opt/challenges/lesson24/pieces.csv | paste -sd '' | tr 'A-Za-z' 'N-ZA-Mn-za-m' > ~/lesson24/flag.txt
cat ~/lesson24/flag.txt

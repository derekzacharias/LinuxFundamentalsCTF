#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/lesson13
tar -xzf /opt/challenges/lesson13/treasure.bin -C ~/lesson13
tar -xzf ~/lesson13/level2.tar.gz -C ~/lesson13
unzip -o -q ~/lesson13/level3.zip -d ~/lesson13
cat ~/lesson13/level3/flag.txt

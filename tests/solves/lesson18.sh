#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/lesson18
grep ' 418 ' /opt/data/lesson18/access.log | grep -oE 'piece=[A-Za-z0-9_{}]+' | cut -d= -f2 | paste -sd '' > ~/lesson18/flag.txt
cat ~/lesson18/flag.txt

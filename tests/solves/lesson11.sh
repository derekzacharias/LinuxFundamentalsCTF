#!/usr/bin/env bash
set -euo pipefail
grep -R REALFLAG /opt/data/lesson11 > ~/lesson11_flag.txt
cat ~/lesson11_flag.txt

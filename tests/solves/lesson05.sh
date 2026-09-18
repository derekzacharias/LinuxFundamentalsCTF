#!/usr/bin/env bash
set -euo pipefail
grep FLAGLINE /opt/data/lesson5_data.txt | tee ~/lesson5_flag.txt

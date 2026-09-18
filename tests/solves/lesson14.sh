#!/usr/bin/env bash
set -euo pipefail
cat "$(readlink -f /opt/challenges/lesson14/chain_start)" > ~/lesson14_flag.txt
cp /opt/challenges/lesson14/source.txt ~/source.txt
ln -f ~/source.txt ~/lesson14_backup
cat ~/lesson14_flag.txt

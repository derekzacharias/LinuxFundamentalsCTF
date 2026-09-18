#!/usr/bin/env bash
set -euo pipefail
rm -rf ~/project3
cp -a /opt/challenges/lesson3_template ~/project3
mkdir -p ~/project3/secret
mv ~/project3/flag.part1 ~/project3/flag.part2 ~/project3/secret/
cat ~/project3/secret/flag.part1 ~/project3/secret/flag.part2 > ~/project3/final.flag
cat ~/project3/final.flag

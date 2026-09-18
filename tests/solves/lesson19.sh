#!/usr/bin/env bash
set -euo pipefail
whoami > /opt/challenges/lesson19/shared/notes_"$(whoami)"
mkdir -p ~/lesson19
whoami > ~/lesson19/shared_notes.txt
cat /opt/flags/lesson19.flag

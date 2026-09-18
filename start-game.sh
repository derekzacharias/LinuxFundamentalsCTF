#!/usr/bin/env bash
set -euo pipefail
# Convenience wrapper so you can start the CTF from the repo root.
if command -v start-game >/dev/null 2>&1; then
  exec start-game "$@"
fi
cat <<'EOS' >&2
start-game is not installed in your PATH.

Install the course assets, then re-run ./start-game.sh:
  sudo ./scripts/install.sh
EOS
exit 1

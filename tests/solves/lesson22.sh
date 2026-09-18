#!/usr/bin/env bash
set -euo pipefail
# Solver: student actions for lesson 22 (safe to run more than once).
if [[ ! -f ~/.ssh/id_ctf22 ]]; then
  ssh-keygen -q -t ed25519 -f ~/.ssh/id_ctf22 -N ''
fi
pub=$(cat ~/.ssh/id_ctf22.pub)
if ! sudo grep -qxF "$pub" /home/ctf22/.ssh/authorized_keys 2>/dev/null; then
  printf '%s\n' "$pub" | sudo tee -a /home/ctf22/.ssh/authorized_keys >/dev/null
fi
ssh -i ~/.ssh/id_ctf22 -o BatchMode=yes -o StrictHostKeyChecking=accept-new ctf22@localhost 'cat /home/ctf22/flag.txt'

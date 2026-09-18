#!/usr/bin/env bash
set -euo pipefail
ssh-keygen -t ed25519 -f ~/.ssh/id_ctf22 -N '' -q
sudo bash -c "cat $HOME/.ssh/id_ctf22.pub >> /home/ctf22/.ssh/authorized_keys"
ssh -i ~/.ssh/id_ctf22 -o BatchMode=yes -o StrictHostKeyChecking=accept-new ctf22@localhost 'cat /home/ctf22/flag.txt'

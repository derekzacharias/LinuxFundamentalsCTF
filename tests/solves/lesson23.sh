#!/usr/bin/env bash
set -euo pipefail
sudo sh -c 'grep -q flag.service.local /etc/hosts || echo "127.0.0.1 flag.service.local" >> /etc/hosts'
curl -fsS -H 'Host: flag.service.local' http://127.0.0.1:9099/

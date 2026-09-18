#!/usr/bin/env bash
set -euo pipefail
sudo systemctl start lesson20.service
sudo systemctl enable lesson20.service
for _ in $(seq 1 10); do
  if journalctl -u lesson20 --no-pager -n 200 2>/dev/null | grep -q 'FLAG{lesson_20'; then break; fi
  if sudo -n journalctl -u lesson20 --no-pager -n 200 2>/dev/null | grep -q 'FLAG{lesson_20'; then break; fi
  sleep 2
done
{ journalctl -u lesson20 --no-pager -n 200 2>/dev/null || sudo -n journalctl -u lesson20 --no-pager -n 200 2>/dev/null; } | grep 'FLAG{lesson_20' | head -1

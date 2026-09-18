#!/usr/bin/env bash
set -euo pipefail
cat > ~/lesson10.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
count=$(find "$1" -maxdepth 1 -name '*.log' | wc -l)
if [[ $count -eq 7 ]]; then
  grep -h 'FLAG{lesson_10' "$1"/*.log
fi
EOS
chmod +x ~/lesson10.sh
~/lesson10.sh /opt/data/lesson10_logs

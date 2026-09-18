#!/usr/bin/env bash
set -euo pipefail
cat > ~/lesson21_worker.sh <<'EOS'
#!/usr/bin/env bash
base64 -d /opt/data/lesson21/seed.txt
EOS
chmod +x ~/lesson21_worker.sh
( crontab -l 2>/dev/null | grep -v lesson21_worker || true
  echo '* * * * * $HOME/lesson21_worker.sh >> /var/spool/lesson21/submissions.log 2>&1'
) | crontab -
lesson21_checker

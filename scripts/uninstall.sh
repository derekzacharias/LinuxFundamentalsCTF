#!/usr/bin/env bash
set -euo pipefail
# uninstall.sh — removes the Linux Fundamentals CTF from a lab machine.
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run with sudo: sudo bash $0" >&2
  exit 1
fi

systemctl disable --now lesson6-logger.service lesson12-server.service lesson23-server.service lesson20.service 2>/dev/null || true
rm -f /etc/systemd/system/lesson6-logger.service /etc/systemd/system/lesson12-server.service \
      /etc/systemd/system/lesson20.service /etc/systemd/system/lesson23-server.service
systemctl daemon-reload

rm -rf /opt/lessons /opt/flags /opt/data /opt/challenges /opt/ctf /opt/tools
rm -f /usr/local/bin/ctf /usr/local/bin/lessons /usr/local/bin/lesson /usr/local/bin/hint \
      /usr/local/bin/submit_flag /usr/local/bin/check_flag /usr/local/bin/progress \
      /usr/local/bin/validate_lesson /usr/local/bin/start-game /usr/local/bin/start-learning \
      /usr/local/bin/ctf-welcome /usr/local/bin/lesson6-logger.sh /usr/local/bin/lesson7_checker \
      /usr/local/bin/lesson12_server.py /usr/local/bin/lesson16_worker.sh \
      /usr/local/bin/lesson20_flag.sh /usr/local/bin/lesson21_checker /usr/local/bin/lesson23_server.py
rm -rf /var/spool/lesson21 /var/log/lesson6.log /var/log/lesson12_access.log
rm -f /etc/motd

if id ctf22 >/dev/null 2>&1; then userdel -r ctf22 2>/dev/null || true; fi
for g in ctf8 ctf14 ctf19 ctf21; do groupdel "$g" 2>/dev/null || true; done

echo "[+] Uninstalled. (Per-user files in ~ — .lesson2, project3, get_flag4.sh, ~/.ctf_state — are left in place.)"
